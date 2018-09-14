defmodule Core.Employees do
  @moduledoc false

  use Core.Search, Core.PRMRepo

  import Core.API.Helpers.Connection
  import Ecto.Changeset
  import Core.Contracts.ContractSuspender
  import Core.Context, only: [authorize_legal_entity_id: 3]

  alias Core.Contracts
  alias Core.Contracts.Contract
  alias Core.EmployeeRequests.EmployeeRequest, as: Request
  alias Core.EmployeeRequests
  alias Core.Employees.Employee
  alias Core.Employees.EmployeeCreator
  alias Core.Employees.Search
  alias Core.Employees.UserRoleCreator
  alias Core.EventManager
  alias Core.Parties
  alias Core.PRMRepo
  alias Ecto.Changeset
  alias Scrivener.Page

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]

  @doctor Employee.type(:doctor)
  @pharmacist Employee.type(:pharmacist)

  @required_fields ~w(
    party_id
    legal_entity_id
    position
    status
    employee_type
    is_active
    inserted_by
    updated_by
    start_date
  )a

  @optional_fields ~w(
    division_id
    status_reason
    end_date
    speciality
  )a

  def list(params) do
    %Search{}
    |> changeset(params)
    |> search(params, Employee)
  end

  @doc """
  For internal use
  """
  def list!(params) do
    Employee
    |> where([e], ^params)
    |> PRMRepo.all()
    |> load_references()
  end

  def get_active_by_party_id(party_id) do
    Employee
    |> where([e], e.is_active)
    |> where([e], e.status == ^Employee.status(:approved))
    |> where([e], e.party_id == ^party_id)
    |> PRMRepo.all()
  end

  def get_search_query(Employee = entity, %{ids: _} = changes) do
    entity
    |> super(convert_comma_params_to_where_in_clause(changes, :ids, :id))
    |> load_references()
  end

  def get_search_query(Employee = entity, changes) do
    params =
      changes
      |> Map.drop([:tax_id, :no_tax_id, :edrpou])
      |> Map.to_list()

    entity
    |> select([e], e)
    |> query_tax_id(Map.get(changes, :tax_id))
    |> query_no_tax_id(Map.get(changes, :no_tax_id))
    |> query_edrpou(Map.get(changes, :edrpou))
    |> where(^params)
    |> load_references()
  end

  def get_by_id!(id) do
    Employee
    |> get_by_id_query(id)
    |> PRMRepo.one!()
  end

  def get_by_id(id) do
    Employee
    |> get_by_id_query(id)
    |> PRMRepo.one()
  end

  def get_by_id(id, headers) do
    client_id = get_client_id(headers)

    with employee <- get_by_id!(id),
         {:ok, client_type} <- @mithril_api.get_client_type_name(client_id, headers),
         :ok <- authorize_legal_entity_id(employee.legal_entity_id, client_id, client_type) do
      {:ok,
       employee
       |> PRMRepo.preload(:party)
       |> PRMRepo.preload(:division)
       |> PRMRepo.preload(:legal_entity)}
    end
  end

  defp get_by_id_query(query, id) do
    query
    |> where([e], e.id == ^id)
    |> join(:left, [e], p in assoc(e, :party))
    |> join(:left, [e], le in assoc(e, :legal_entity))
    |> preload([e, p, le], party: p, legal_entity: le)
  end

  def get_by_ids(ids) when is_list(ids) do
    Employee
    |> where([d], d.id in ^ids)
    |> PRMRepo.all()
  end

  def get_preloaded_by_ids(ids) when is_list(ids) do
    Employee
    |> where([d], d.id in ^ids)
    |> load_references()
    |> PRMRepo.all()
  end

  def create(attrs, author_id) do
    %Employee{}
    |> changeset(attrs)
    |> PRMRepo.insert_and_log(author_id)
  end

  def get_by_user_id(id) do
    Employee
    |> join(:left, [e], p in assoc(e, :party))
    |> join(:left, [e, p], pu in assoc(p, :users))
    |> where([e, p, pu], pu.user_id == ^id)
    |> PRMRepo.all()
  end

  def create_or_update_employee(
        %Request{data: %{"employee_id" => employee_id} = employee_request},
        headers
      ) do
    employee = get_by_id!(employee_id)
    party = Parties.get_by_id!(employee.party.id)
    party_update_params = EmployeeRequests.create_party_params(employee_request)

    employee_update_params =
      Map.merge(employee_request, %{
        "employee_type" => employee.employee_type,
        "updated_by" => get_consumer_id(headers),
        "speciality" => EmployeeRequests.get_employee_speciality(employee_request)
      })

    with {:ok, _} <- EmployeeCreator.suspend_party_contracts(party, employee_request, headers),
         {:ok, _} <- EmployeeCreator.create_party_user(party, headers),
         :ok <- UserRoleCreator.create(employee, headers),
         %Changeset{valid?: true} = party_changeset <- Parties.changeset(party, party_update_params),
         %Changeset{valid?: true} = employee_changeset <- changeset(employee, employee_update_params) do
      if maybe_suspend_contracts?(party_changeset, :party) || maybe_suspend_contracts?(employee_changeset, :employee) do
        transaction_update_with_contract(party_changeset, employee_changeset, headers)
      else
        __MODULE__.update(employee, employee_update_params, get_consumer_id(headers))
      end
    end
  end

  def create_or_update_employee(%Request{} = employee_request, headers) do
    with {:ok, employee} <- EmployeeCreator.create(employee_request, headers),
         :ok <- UserRoleCreator.create(employee, headers) do
      {:ok, employee}
    end
  end

  def update(%Employee{status: old_status} = employee, attrs, author_id) do
    with {:ok, employee} <-
           employee
           |> changeset(attrs)
           |> PRMRepo.update_and_log(author_id),
         _ <- EventManager.insert_change_status(employee, old_status, employee.status, author_id) do
      {:ok, load_references(employee)}
    end
  end

  def update_with_ops_contract(%Employee{status: old_status} = employee, attrs, headers) do
    with {:ok, employee} <- transaction_update_with_contract(nil, changeset(employee, attrs), headers) do
      EventManager.insert_change_status(
        employee,
        old_status,
        employee.status,
        get_consumer_id(headers)
      )

      {:ok, employee}
    end
  end

  defp transaction_update_with_contract(party_changeset, employee_changeset, headers) do
    author_id = get_consumer_id(headers)
    employee_id = Changeset.get_field(employee_changeset, :id)

    get_contracts_params = %{
      contractor_owner_id: employee_id,
      status: Contract.status(:verified),
      is_suspended: false
    }

    PRMRepo.transaction(fn ->
      {:ok, %Page{entries: contracts}, _} = Contracts.list(get_contracts_params, nil, headers)
      {:ok, _} = suspend_contracts(contracts)

      with {:ok, _} <- transaction_update_party(party_changeset, author_id),
           {:ok, result} <- EctoTrail.update_and_log(PRMRepo, employee_changeset, author_id) do
        load_references(result)
      else
        {:error, reason} ->
          PRMRepo.rollback(reason)
      end
    end)
  end

  defp transaction_update_party(nil, _author_id), do: {:ok, "party not changed"}

  defp transaction_update_party(party_changeset, author_id) do
    EctoTrail.update_and_log(PRMRepo, party_changeset, author_id)
  end

  defp changeset(%Search{} = employee, attrs) do
    cast(employee, attrs, Search.__schema__(:fields))
  end

  defp changeset(%Employee{} = employee, attrs) do
    employee
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> required_fields(employee)
    |> put_additional_info(attrs)
    |> validate_employee_type()
    |> foreign_key_constraint(:legal_entity_id)
    |> foreign_key_constraint(:division_id)
    |> foreign_key_constraint(:party_id)
  end

  defp required_fields(changeset, %Employee{employee_type: "DOCTOR"}) do
    validate_required(changeset, @required_fields ++ [:speciality])
  end

  defp required_fields(changeset, %Employee{employee_type: "PHARMACIST"}) do
    validate_required(changeset, @required_fields ++ [:speciality])
  end

  defp required_fields(changeset, _) do
    validate_required(changeset, @required_fields)
  end

  defp put_additional_info(%Ecto.Changeset{valid?: true} = changeset, %{"doctor" => doctor}) do
    put_change(changeset, :additional_info, doctor)
  end

  defp put_additional_info(%Ecto.Changeset{valid?: true} = changeset, %{
         "pharmacist" => pharmacist
       }) do
    put_change(changeset, :additional_info, pharmacist)
  end

  defp put_additional_info(changeset, _), do: changeset

  defp validate_employee_type(%Ecto.Changeset{changes: %{employee_type: @doctor}} = changeset) do
    validate_required(changeset, [:additional_info])
  end

  defp validate_employee_type(%Ecto.Changeset{changes: %{employee_type: @pharmacist}} = changeset) do
    validate_required(changeset, [:additional_info])
  end

  defp validate_employee_type(changeset), do: changeset

  defp load_references(%Ecto.Query{} = query) do
    query
    |> preload(:party)
    |> preload(:division)
    |> preload(:legal_entity)
  end

  defp load_references(%Employee{} = employee) do
    employee
    |> PRMRepo.preload(:party)
    |> PRMRepo.preload(:division)
    |> PRMRepo.preload(:legal_entity)
  end

  defp load_references(employees) when is_list(employees) do
    Enum.map(employees, &load_references/1)
  end

  defp load_references({:ok, entity}), do: {:ok, load_references(entity)}
  defp load_references({:error, _} = error), do: error

  defp convert_comma_params_to_where_in_clause(changes, param_name, db_field) do
    changes
    |> Map.put(db_field, {String.split(changes[param_name], ","), :in})
    |> Map.delete(param_name)
  end

  def query_tax_id(query, nil), do: query

  def query_tax_id(query, tax_id) do
    query
    |> join(:left, [e], p in assoc(e, :party))
    |> where([..., p], p.tax_id == ^tax_id)
  end

  def query_no_tax_id(query, nil), do: query

  def query_no_tax_id(query, no_tax_id) do
    query
    |> join(:left, [e], p in assoc(e, :party))
    |> where([..., p], p.no_tax_id == ^no_tax_id)
  end

  def query_edrpou(query, nil), do: query

  def query_edrpou(query, edrpou) do
    query
    |> join(:left, [e], le in assoc(e, :legal_entity))
    |> where([..., le], le.edrpou == ^edrpou)
  end
end
