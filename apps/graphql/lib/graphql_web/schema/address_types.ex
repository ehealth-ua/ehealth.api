defmodule GraphQLWeb.Schema.AddressTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  object :address do
    field(:type, non_null(:address_type))
    field(:country, non_null(:string))
    field(:area, non_null(:string))
    field(:region, :string)
    field(:settlement, non_null(:string))
    field(:settlement_type, non_null(:string))
    field(:settlement_id, non_null(:id))
    field(:street_type, :string)
    field(:street, :string)
    field(:building, non_null(:string))
    field(:apartment, :string)
    field(:zip, non_null(:string))
  end

  enum :address_type do
    value(:residence, as: "RESIDENCE")
    value(:registration, as: "REGISTRATION")
  end
end
