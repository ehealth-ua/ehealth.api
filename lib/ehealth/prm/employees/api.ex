defmodule EHealth.PRM.Employees do
  @moduledoc false

  alias EHealth.Repo
  alias EHealth.PRMRepo
  alias EHealth.PRM.Employees.Schema, as: Employee
  alias EHealth.PRM.Employees.Search
  alias Ecto.Multi
  use EHealth.PRM.Search

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

  @doctor Employee.type(:doctor)
  @pharmacist Employee.type(:pharmacist)

  def get_employee_by_id!(id) do
    Employee
    |> get_employee_by_id_query(id)
    |> PRMRepo.one!
  end

  def get_employee_by_id(id) do
    Employee
    |> get_employee_by_id_query(id)
    |> PRMRepo.one
  end

  defp get_employee_by_id_query(query, id) do
    query
    |> where([e], e.id == ^id)
    |> join(:left, [e], p in assoc(e, :party))
    |> join(:left, [e], le in assoc(e, :legal_entity))
    |> preload([e, p, le], [party: p, legal_entity: le])
  end

  @doc """
  For internal use
  """
  def list(params) do
    Employee
    |> where([e], ^params)
    |> PRMRepo.all
    |> load_references()
  end

  def get_employees(params) do
    %Search{}
    |> changeset(params)
    |> search(params, Employee)
  end

  def get_by_ids(ids) do
    Employee
    |> where([e], e.id in ^ids)
    |> PRMRepo.all()
  end

  def update_all(query, updates) do
    Multi.new
    |> Multi.update_all(:employee_requests, query, set: updates)
    |> Repo.transaction
  end

  def create_employee(attrs, author_id) do
    %Employee{}
    |> changeset(attrs)
    |> PRMRepo.insert_and_log(author_id)
  end

  def update_employee(%Employee{} = employee, attrs, author_id) do
    with {:ok, employee} <- employee
                            |> changeset(attrs)
                            |> PRMRepo.update_and_log(author_id)
    do
      {:ok, load_references(employee)}
    end
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

  defp convert_comma_params_to_where_in_clause(changes, param_name, db_field) do
    changes
    |> Map.put(db_field, {String.split(changes[param_name], ","), :in})
    |> Map.delete(param_name)
  end
end
