defmodule EHealth.Employees do
  @moduledoc false

  use EHealth.Search, EHealth.PRMRepo

  import Ecto.Changeset
  import EHealth.Utils.Connection
  import EHealth.Plugs.ClientContext, only: [authorize_legal_entity_id: 3]

  alias EHealth.API.Mithril
  alias EHealth.EmployeeRequests.EmployeeRequest, as: Request
  alias EHealth.Employees.EmployeeCreator
  alias EHealth.Employees.UserRoleCreator
  alias EHealth.Employees.Employee
  alias EHealth.Employees.Search
  alias EHealth.PRMRepo
  alias EHealth.Parties

  @doctor Employee.type(:doctor)
  @pharmacist Employee.type(:pharmacist)

  @search_fields ~w(
    ids
    party_id
    legal_entity_id
    division_id
    status
    employee_type
    is_active
    tax_id
    edrpou
  )a

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
    |> PRMRepo.all
    |> load_references()
  end

  def get_search_query(Employee = entity, %{ids: _} = changes) do
    entity
    |> super(convert_comma_params_to_where_in_clause(changes, :ids, :id))
    |> load_references()
  end
  def get_search_query(Employee = entity, changes) do
    params =
      changes
      |> Map.drop([:tax_id, :edrpou])
      |> Map.to_list()

    entity
    |> select([e], e)
    |> query_tax_id(Map.get(changes, :tax_id))
    |> query_edrpou(Map.get(changes, :edrpou))
    |> where(^params)
    |> load_references()
  end

  def get_by_id!(id) do
    Employee
    |> get_by_id_query(id)
    |> PRMRepo.one!
  end

  def get_by_id(id) do
    Employee
    |> get_by_id_query(id)
    |> PRMRepo.one
  end

  def get_by_id(id, headers) do
    client_id = get_client_id(headers)
    with employee <- get_by_id!(id),
         {:ok, client_type} <- Mithril.get_client_type_name(client_id, headers),
         :ok <- authorize_legal_entity_id(employee.legal_entity_id, client_id, client_type)
    do
      {:ok, employee
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
    |> preload([e, p, le], [party: p, legal_entity: le])
  end

  def get_by_ids(ids) when is_list(ids) do
    Employee
    |> where([d], d.id in ^ids)
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

  def update(%Employee{} = employee, attrs, author_id) do
    with {:ok, employee} <- employee
                            |> changeset(attrs)
                            |> PRMRepo.update_and_log(author_id)
    do
      {:ok, load_references(employee)}
    end
  end

  defp changeset(%Search{} = employee, attrs) do
    cast(employee, attrs, @search_fields)
  end
  defp changeset(%Employee{} = employee, attrs) do
    employee
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> put_additional_info(attrs)
    |> validate_employee_type()
    |> foreign_key_constraint(:legal_entity_id)
    |> foreign_key_constraint(:division_id)
    |> foreign_key_constraint(:party_id)
  end

  defp put_additional_info(%Ecto.Changeset{valid?: true} = changeset, %{"doctor" => doctor}) do
    put_change(changeset, :additional_info, doctor)
  end
  defp put_additional_info(%Ecto.Changeset{valid?: true} = changeset, %{"pharmacist" => pharmacist}) do
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

  def create_or_update_employee(%Request{data: %{"employee_id" => employee_id} = employee_request}, req_headers) do
    with employee <- get_by_id!(employee_id),
         party_id <- employee |> Map.get(:party, %{}) |> Map.get(:id),
         party <- Parties.get_by_id!(party_id),
         {:ok, _} <- EmployeeCreator.create_party_user(party, req_headers),
         {:ok, _} <- Parties.update(party, Map.fetch!(employee_request, "party"), employee_id),
         params <- employee_request
           |> update_additional_info(employee)
           |> Map.put("employee_type", employee.employee_type)
           |> Map.put("updated_by", get_consumer_id(req_headers))
    do
      __MODULE__.update(employee, params, get_consumer_id(req_headers))
    end
  end
  def create_or_update_employee(%Request{} = employee_request, req_headers) do
    with {:ok, employee} <- EmployeeCreator.create(employee_request, req_headers),
         :ok <- UserRoleCreator.create(employee, req_headers)
    do
      {:ok, employee}
    end
  end

  defp update_additional_info(employee_request, %Employee{employee_type: @doctor, additional_info: info}) do
    Map.put(employee_request, "doctor", Map.merge(info, Map.get(employee_request, "doctor")))
  end
  defp update_additional_info(employee_request, %Employee{employee_type: @pharmacist, additional_info: info}) do
    Map.put(employee_request, "pharmacist", Map.merge(info, Map.get(employee_request, "pharmacist")))
  end
  defp update_additional_info(employee_request, _), do: employee_request

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

  def query_edrpou(query, nil), do: query
  def query_edrpou(query, edrpou) do
    query
    |> join(:left, [e], le in assoc(e, :legal_entity))
    |> where([..., le], le.edrpou == ^edrpou)
  end
end
