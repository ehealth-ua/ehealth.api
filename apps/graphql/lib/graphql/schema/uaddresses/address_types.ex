defmodule GraphQL.Schema.AddressTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  input_object :address_filter do
    field(:type, :string)
    field(:settlement_id, :string)
  end

  object :address do
    # Dictionary: ADDRESS_TYPE
    field(:type, non_null(:string))
    field(:country, non_null(:string))
    field(:area, non_null(:string))
    field(:region, :string)
    field(:settlement, non_null(:string))
    field(:settlement_type, non_null(:string))
    field(:settlement_id, non_null(:id))
    # Dictionary: STREET_TYPE
    field(:street_type, :string)
    field(:street, :string)
    field(:building, :string)
    field(:apartment, :string)
    field(:zip, :string)
  end
end
