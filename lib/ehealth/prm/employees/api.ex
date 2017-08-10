defmodule EHealth.PRM.Employees do
  @moduledoc false

  alias EHealth.PRMRepo
  alias EHealth.PRM.Employees.Schema, as: Employee
  alias EHealth.PRM.Employees.Search
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

  def get_employee_by_id!(id) do
    PRMRepo.get!(Employee, id)
  end

  def get_employee_by_id(id) do
    PRMRepo.get(Employee, id)
  end

  def get_employees(params) do
    %Search{}
    |> changeset(params)
    |> search(params, Employee, Confex.get_env(:ehealth, :employees_per_page))
    |> preload_relations(params)
  end

  defp changeset(%Search{} = employee, attrs) do
    cast(employee, attrs, @search_fields)
  end

  defp changeset(%Employee{} = employee, attrs) do
    employee
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> cast_assoc(:doctor)
    |> validate_required(@required_fields)
    |> validate_employee_type()
    |> foreign_key_constraint(:legal_entity_id)
    |> foreign_key_constraint(:division_id)
    |> foreign_key_constraint(:party_id)
  end

  defp validate_employee_type(%Ecto.Changeset{changes: %{employee_type: "DOCTOR"}} = changeset) do
    validate_required(changeset, [:doctor])
  end
  defp validate_employee_type(changeset), do: changeset

  def preload_relations({employees, %Ecto.Paging{} = paging}, params) when length(employees) > 0 do
    {preload_relations(employees, params), paging}
  end
  def preload_relations({:ok, employees}, params) do
    {:ok, preload_relations(employees, params)}
  end
  def preload_relations(repo, %{"expand" => _}) when length(repo) > 0 do
    do_preload(repo)
  end
  def preload_relations(err, _params), do: err

  defp do_preload(repo) do
    repo
    |> PRMRepo.preload(:doctor)
    |> PRMRepo.preload(:party)
    |> PRMRepo.preload(:division)
    |> PRMRepo.preload(:legal_entity)
  end
end
