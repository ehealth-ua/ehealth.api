defmodule GraphQLWeb.Schema.RegionTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  node object(:region) do
    field(:database_id, non_null(:uuid))
    field(:name, non_null(:string))
    field(:koatuu, non_null(:string))

    # TODO: add support for one-to-many batches to Dataloader.Rpc
    # connection field(:districts, node_type: :district) do
    #   arg(:filter, :district_filter)
    #   arg(:order_by, :district_order_by, default_value: :inserted_at_desc)

    #   middleware(Filtering, name: :like)

    #   resolve(dataloader(Uaddresses, {:search_districts, :many, :id, :region_id}))
    # end

    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))
  end
end
