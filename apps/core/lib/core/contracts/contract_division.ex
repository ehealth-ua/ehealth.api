defmodule Core.Contracts.ContractDivision do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Core.Contracts.Contract
  alias Ecto.UUID

  @primary_key {:id, :binary_id, autogenerate: true}
  @derive {Jason.Encoder, except: [:__meta__, :contract]}

  @fields_required ~w(
    division_id
    inserted_by
    updated_by
  )a

  schema "contract_divisions" do
    field(:division_id, UUID)
    field(:inserted_by, UUID)
    field(:updated_by, UUID)

    belongs_to(:contract, Contract, type: UUID)

    timestamps()
  end

  def changeset(%__MODULE__{} = contract_division, attrs) do
    contract_division
    |> cast(attrs, @fields_required)
    |> validate_required(@fields_required)
  end
end
