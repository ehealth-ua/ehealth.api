defmodule Core.Contracts.ContractDivision do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Core.Divisions.Division
  alias Ecto.UUID

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Jason.Encoder, except: [:__meta__, :contract]}

  @fields_required ~w(
    division_id
    inserted_by
    updated_by
  )a

  schema "contract_divisions" do
    field(:inserted_by, UUID)
    field(:updated_by, UUID)
    # because of polymorphic Contract, it's impossible to use `belongs_to` for :contract field
    field(:contract_id, UUID)

    belongs_to(:division, Division, type: UUID)

    timestamps(type: :utc_datetime_usec)
  end

  def changeset(%__MODULE__{} = contract_division, attrs) do
    contract_division
    |> cast(attrs, @fields_required)
    |> validate_required(@fields_required)
  end
end
