defmodule Core.Divisions.DivisionAddress do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, except: [:__meta__]}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "division_addresses" do
    field(:division_id, Ecto.UUID)
    field(:zip, :string)
    field(:area, :string)
    field(:type, :string)
    field(:region, :string)
    field(:street, :string)
    field(:country, :string)
    field(:building, :string)
    field(:apartment, :string)
    field(:settlement, :string)
    field(:street_type, :string)
    field(:settlement_id, Ecto.UUID)
    field(:settlement_type, :string)
  end

  def changeset(division_address, params \\ %{}) do
    cast(division_address, params, __MODULE__.__schema__(:fields))
  end
end
