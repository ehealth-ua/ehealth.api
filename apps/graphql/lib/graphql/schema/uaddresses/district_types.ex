defmodule GraphQL.Schema.DistrictTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  input_object :district_filter do
    field(:name, :string)
  end

  enum :district_order_by do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:name_asc)
    value(:name_desc)
  end

  connection(node_type: :district) do
    field :nodes, list_of(:district) do
      resolve(fn _, %{source: conn} ->
        {:ok, Enum.map(conn.edges, & &1.node)}
      end)
    end

    edge(do: nil)
  end

  node object(:district) do
    field(:database_id, non_null(:uuid))
    field(:name, non_null(:string))
    field(:koatuu, non_null(:string))
    field(:region, non_null(:region))

    # TODO: add support for one-to-many batches to Dataloader.Rpc
    # connection field(:settlements, node_type: :settlement) do
    #   arg(:filter, :settlement_filter)
    #   arg(:order_by, :settlement_order_by, default_value: :inserted_at_desc)

    #   middleware(Filtering, name: :like)

    #   resolve(dataloader(Uaddresses, {:search_settlements, :many, :id, :settlement_id}))
    # end

    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end
end
