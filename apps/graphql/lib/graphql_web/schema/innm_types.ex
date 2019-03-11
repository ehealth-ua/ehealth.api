defmodule GraphQLWeb.Schema.INNMTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  input_object :innm_filter do
    field(:database_id, :uuid)
  end

  enum :innm_order_by do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
  end

  node object(:innm) do
    field(:database_id, non_null(:uuid))
    field(:name, non_null(:string))
    field(:sctid, :string)
    field(:name_original, non_null(:string))
    field(:is_active, non_null(:boolean))

    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end
end
