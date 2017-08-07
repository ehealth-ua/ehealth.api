defmodule EHealth.PRM.EmployeeDoctors.Schema do
  @moduledoc false

  alias EHealth.PRM.Employees.Schema, as: Employee

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "employee_doctors" do
    field :science_degree, :map
    field :qualifications, {:array, :map}
    field :educations, {:array, :map}
    field :specialities, {:array, :map}

    belongs_to :employee, Employee, type: Ecto.UUID

    timestamps()
  end
end
