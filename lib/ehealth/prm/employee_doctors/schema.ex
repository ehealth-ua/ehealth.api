defmodule EHealth.PRM.EmployeeDoctors.Schema do
  @moduledoc false

  alias EHealth.PRM.Employees.Schema, as: Employee

  use Ecto.Schema
  import Ecto.Changeset

  @required_fields ~w(educations specialities)a

  @optional_fields ~w(science_degree qualifications)a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "employee_doctors" do
    field :science_degree, :map
    field :qualifications, {:array, :map}
    field :educations, {:array, :map}
    field :specialities, {:array, :map}

    belongs_to :employee, Employee, type: Ecto.UUID

    timestamps()
  end

  def changeset(%__MODULE__{} = doctor, attrs) do
    doctor
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
  end
end
