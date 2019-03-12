defmodule GraphQLWeb.Schema.INNMTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import GraphQLWeb.Resolvers.Helpers.Load, only: [load_by_args: 2]

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.Medications.INNM
  alias GraphQLWeb.Loaders.PRM
  alias GraphQLWeb.Middleware.{Filtering, OrderByArgument}
  alias GraphQLWeb.Resolvers.INNMResolver

  object :innm_queries do
    connection field(:innms, node_type: :innm) do
      meta(:scope, ~w(innm:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      arg(:filter, :innm_filter)
      arg(:order_by, :innm_order_by, default_value: :inserted_at_desc)

      middleware(
        Filtering,
        database_id: :equal,
        sctid: :equal,
        name: :like,
        name_original: :like,
        is_active: :equal
      )

      middleware(OrderByArgument, order_by_arg: :order_by)

      resolve(&INNMResolver.list_innms/2)
    end

    field :innm, :innm do
      meta(:scope, ~w(innm:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      arg(:id, non_null(:id))

      middleware(ParseIDs, id: :innm)

      resolve(load_by_args(PRM, INNM))
    end
  end

  input_object :innm_filter, name: "INNMFilter" do
    field(:database_id, :uuid)
    field(:sctid, :string)
    field(:name, :string)
    field(:name_original, :string)
    field(:is_active, :boolean)
  end

  enum :innm_order_by, name: "INNMOrderBy" do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
  end

  object :innm_connection, name: "INNMConnection" do
    field(:page_info, type: non_null(:page_info))
    field(:edges, type: list_of(:innm_edge))

    field :nodes, list_of(:innm) do
      resolve(fn _, %{source: conn} -> {:ok, Enum.map(conn.edges, & &1.node)} end)
    end
  end

  object :innm_edge, name: "INNMEdge" do
    @desc "The item at the end of the edge"
    field(:node, :innm)
    @desc "A cursor for use in pagination"
    field(:cursor, non_null(:string))
  end

  node object(:innm, name: "INNM") do
    field(:database_id, non_null(:uuid))
    field(:name, non_null(:string))
    field(:name_original, non_null(:string))
    field(:sctid, :string)
    field(:is_active, non_null(:boolean))

    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end
end
