defmodule EHealth.LegalEntities.Registry do
  @moduledoc false

  use Ecto.Schema

  alias EHealth.LegalEntities.LegalEntity

  @primary_key {:id, :binary_id, autogenerate: true}

  @type_msp LegalEntity.type(:msp)
  @type_pharmacy LegalEntity.type(:pharmacy)

  def type(:msp), do: @type_msp
  def type(:pharmacy), do: @type_pharmacy

  schema "ukr_med_registries" do
    field :name, :string
    field :edrpou, :string
    field :inserted_by, Ecto.UUID
    field :updated_by, Ecto.UUID
    field :type, :string

    timestamps()
  end
end
