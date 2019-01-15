defmodule Core.Employees do
  @moduledoc false

  use Core.Search, Application.get_env(:core, :repos)[:read_prm_repo]

  import Core.API.Helpers.Connection
  import Ecto.Changeset
  import Core.Context, only: [authorize_legal_entity_id: 3]
  import Core.Contracts.ContractSuspender, only: [suspend_contracts?: 2, suspend_by_contractor_owner_ids: 1]

  alias Core.EmployeeRequests
  alias Core.EmployeeRequests.EmployeeRequest
  alias Core.Employees.Employee
  alias Core.Employees.EmployeeCreator
  alias Core.Employees.Search
  alias Core.Employees.UserRoleCreator
  alias Core.EventManager
  alias Core.Parties
  alias Core.PRMRepo
  alias Ecto.Changeset

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]
  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

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
    |> @read_prm_repo.all()
    |> load_references()
  end

  def get_active_by_party_id(party_id) do
    Employee
    |> where([e], e.is_active)
    |> where([e], e.status == ^Employee.status(:approved))
    |> where([e], e.party_id == ^party_id)
    |> @read_prm_repo.all()
  end

  def has_contract_owner_employees(party_id, legal_entity_id, types) do
    Employee
    |> where([e], e.is_active)
    |> where([e], e.status == ^Employee.status(:approved))
    |> where([e], e.party_id == ^party_id)
    |> where([e], e.legal_entity_id == ^legal_entity_id)
    |> where([e], e.employee_type in ^types)
    |> @read_prm_repo.aggregate(:count, :id) > 0
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
    |> @read_prm_repo.one!()
  end

  def get_by_id(id) do
    Employee
    |> get_by_id_query(id)
    |> @read_prm_repo.one()
  end

  def get_by_id(id, headers) do
    client_id = get_client_id(headers)

    query =
      Employee
      |> where([e], e.is_active)
      |> get_by_id_query(id)
      |> join(:left, [e], d in assoc(e, :division))
      |> preload([..., d], division: d)

    with employee <- @read_prm_repo.one!(query),
         {:ok, client_type} <- @mithril_api.get_client_type_name(client_id, headers),
         :ok <- authorize_legal_entity_id(employee.legal_entity_id, client_id, client_type) do
      {:ok, employee}
    end
  end

  def fetch_by_id(id) do
    case get_by_id(id) do
      %Employee{} = employee -> {:ok, employee}
      nil -> {:error, {:not_found, "Employee not found"}}
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
    |> @read_prm_repo.all()
  end

  def get_preloaded_by_ids(ids) when is_list(ids) do
    Employee
    |> where([d], d.id in ^ids)
    |> load_references()
    |> @read_prm_repo.all()
  end

  def get_by_id_with_users(id) do
    Employee
    |> where([e], e.id == ^id)
    |> @read_prm_repo.one()
    |> case do
      nil -> nil
      employee -> {:ok, @read_prm_repo.preload(employee, party: [:users])}
    end
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
    |> @read_prm_repo.all()
  end

  def create_or_update_employee(
        %EmployeeRequest{data: %{"employee_id" => employee_id} = employee_request},
        headers
      ) do
    author_id = get_consumer_id(headers)

    employee = get_by_id!(employee_id)

    employee_update_params =
      Map.merge(employee_request, %{
        "employee_type" => employee.employee_type,
        "updated_by" => author_id,
        "speciality" => EmployeeRequests.get_employee_speciality(employee_request)
      })

    party = Parties.get_by_id!(employee.party.id)
    party_update_params = EmployeeRequests.create_party_params(employee_request)

    with {:ok, _} <- EmployeeCreator.create_party_user(party, headers),
         :ok <- UserRoleCreator.create(employee, headers),
         %Changeset{valid?: true} = party_changeset <- Parties.changeset(party, party_update_params),
         :ok <- update_party(party_changeset, author_id),
         :ok <- suspend_contracts(party_changeset) do
      __MODULE__.update(employee, employee_update_params, get_consumer_id(headers))
    end
  end

  def create_or_update_employee(%EmployeeRequest{} = employee_request, headers) do
    with {:ok, employee} <- EmployeeCreator.create(employee_request, headers),
         :ok <- UserRoleCreator.create(employee, headers) do
      {:ok, employee}
    end
  end

  def update(%Employee{status: old_status} = employee, params, author_id) do
    with {:ok, employee} <-
           employee
           |> changeset(params)
           |> PRMRepo.update_and_log(author_id),
         _ <- EventManager.insert_change_status(employee, old_status, employee.status, author_id) do
      {:ok, load_references(employee)}
    end
  end

  def update_with_ops_contract(%Employee{id: employee_id, status: old_status} = employee, params, author_id) do
    PRMRepo.transaction(fn ->
      with %Changeset{valid?: true} = employee_changeset <- changeset(employee, params),
           {:ok, employee} <- EctoTrail.update_and_log(PRMRepo, employee_changeset, author_id),
           :ok <- suspend_by_contractor_owner_ids([employee_id]),
           _ <- EventManager.insert_change_status(employee, old_status, employee.status, author_id) do
        load_references(employee)
      else
        %Changeset{} = changeset -> PRMRepo.rollback(changeset)
        {:error, reason} -> PRMRepo.rollback(reason)
      end
    end)
  end

  def suspend_contracts(%Changeset{} = party_changeset) do
    party_id = Changeset.get_field(party_changeset, :id)

    if suspend_contracts?(party_changeset, :party) do
      Employee
      |> select([e], e.id)
      |> where([e], e.party_id == ^party_id)
      |> @read_prm_repo.all()
      |> suspend_by_contractor_owner_ids()
    else
      :ok
    end
  end

  defp update_party(%Changeset{changes: changes}, _) when changes == %{}, do: :ok

  defp update_party(party_changeset, author_id) do
    with {:ok, _party} <- EctoTrail.update_and_log(PRMRepo, party_changeset, author_id) do
      :ok
    end
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
    |> @read_prm_repo.preload(:party)
    |> @read_prm_repo.preload(:division)
    |> @read_prm_repo.preload(:legal_entity)
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
