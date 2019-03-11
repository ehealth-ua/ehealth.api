defmodule Core.Contracts.ContractEmployee do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Core.Contracts.CapitationContract
  alias Core.Divisions.Division
  alias Core.Employees.Employee
  alias Ecto.UUID

  @fields_required ~w(
    start_date
    employee_id
    division_id
    staff_units
    declaration_limit
    inserted_by
    updated_by
    )a

  @fields_optional ~w(
    end_date
  )a

  @derive {Jason.Encoder, except: [:__meta__, :contract]}
  @primary_key {:id, :binary_id, autogenerate: true}
  schema "contract_employees" do
    field(:staff_units, :float)
    field(:declaration_limit, :integer)
    field(:start_date, :naive_datetime)
    field(:end_date, :naive_datetime)
    field(:inserted_by, UUID)
    field(:updated_by, UUID)

    belongs_to(:contract, CapitationContract, type: UUID, foreign_key: :contract_id)
    belongs_to(:employee, Employee, type: UUID)
    belongs_to(:division, Division, type: UUID)

    timestamps(type: :utc_datetime)
  end

  def changeset(%__MODULE__{} = contract_employee, attrs) do
    contract_employee
    |> cast(attrs, @fields_required ++ @fields_optional)
    |> validate_required(@fields_required)
  end
end
