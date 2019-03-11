defmodule GraphQLWeb.Schema.SettlementTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 2]

  alias GraphQLWeb.Loaders.Uaddresses
  alias GraphQLWeb.Middleware.Filtering
  alias GraphQLWeb.Resolvers.SettlementResolver

  object :settlement_queries do
    connection field(:settlements, node_type: :settlement) do
      arg(:filter, :settlement_filter)
      arg(:order_by, :settlement_order_by, default_value: :inserted_at_desc)

      middleware(Filtering, name: :like)

      resolve(&SettlementResolver.list_settlements/2)
    end
  end

  input_object :settlement_filter do
    field(:name, :string)
  end

  enum :settlement_order_by do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:mountain_group_asc)
    value(:mountain_group_desc)
    value(:name_asc)
    value(:name_desc)
  end

  connection(node_type: :settlement) do
    field :nodes, list_of(:settlement) do
      resolve(fn _, %{source: conn} ->
        {:ok, Enum.map(conn.edges, & &1.node)}
      end)
    end

    edge(do: nil)
  end

  node object(:settlement) do
    field(:database_id, non_null(:uuid))
    field(:name, non_null(:string))
    field(:koatuu, non_null(:string))
    field(:mountain_group, non_null(:boolean))
    field(:type, non_null(:settlement_type))
    field(:region, non_null(:region), resolve: dataloader(Uaddresses, {:search_regions, :one, :region_id, :id}))
    field(:district, :district, resolve: dataloader(Uaddresses, {:search_districts, :one, :district_id, :id}))

    field(:parent_settlement, :settlement,
      resolve: dataloader(Uaddresses, {:search_settlements, :one, :parent_settlement_id, :id})
    )

    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end

  enum :settlement_type do
    value(:city, as: "CITY")
    value(:settlement, as: "SETTLEMENT")
    value(:township, as: "TOWNSHIP")
    value(:village, as: "VILLAGE")
  end
end
