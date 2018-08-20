defmodule Core.Contracts.ContractEmployee do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Core.Contracts.Contract
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
    field(:employee_id, UUID)
    field(:staff_units, :float)
    field(:declaration_limit, :integer)
    field(:division_id, UUID)
    field(:start_date, :naive_datetime)
    field(:end_date, :naive_datetime)
    field(:inserted_by, UUID)
    field(:updated_by, UUID)

    belongs_to(:contract, Contract, type: UUID)

    timestamps()
  end

  def changeset(%__MODULE__{} = contract_employee, attrs) do
    contract_employee
    |> cast(attrs, @fields_required ++ @fields_optional)
    |> validate_required(@fields_required)
  end
end
