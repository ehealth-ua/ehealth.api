defmodule GraphQL.Schema.ServiceGroupTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import GraphQL.Resolvers.Helpers.Load, only: [load_by_args: 2]

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.Services.ServiceGroup
  alias GraphQL.Loaders.PRM
  alias GraphQL.Middleware.Filtering
  alias GraphQL.Resolvers.ServiceGroup, as: ServiceGroupResolver

  object :service_group_queries do
    connection field(:service_groups, node_type: :service_group) do
      meta(:scope, ~w(service_catalog:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      arg(:filter, :service_group_filter)
      arg(:order_by, :service_group_order_by, default_value: :inserted_at_desc)

      middleware(
        Filtering,
        database_id: :equal,
        name: :like,
        code: :like,
        is_active: :equal,
        parent_group: [
          database_id: :equal,
          name: :like,
          code: :like,
          is_active: :equal
        ]
      )

      resolve(&ServiceGroupResolver.list_service_groups/2)
    end

    field(:service_group, :service_group) do
      meta(:scope, ~w(service_catalog:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      arg(:id, non_null(:id))

      middleware(ParseIDs, id: :service_group)

      resolve(load_by_args(PRM, ServiceGroup))
    end
  end

  input_object :service_group_filter do
    field(:database_id, :uuid)
    field(:name, :string)
    field(:code, :string)
    field(:is_active, :boolean)
    field(:parent_group, :service_group_filter)
  end

  enum :service_group_order_by do
    value(:code_asc)
    value(:code_desc)
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:name_asc)
    value(:name_desc)
  end

  connection node_type: :service_group do
    field :nodes, list_of(:service_group) do
      resolve(fn _, %{source: conn} -> {:ok, Enum.map(conn.edges, & &1.node)} end)
    end

    edge(do: nil)
  end

  node object(:service_group) do
    field(:database_id, non_null(:uuid))
    field(:name, non_null(:string))
    field(:code, non_null(:string))
    field(:is_active, non_null(:boolean))
    field(:request_allowed, non_null(:boolean))
    field(:parent_group, :service_group, resolve: dataloader(PRM))

    connection field(:sub_groups, node_type: :service_group) do
      arg(:filter, :service_group_filter)
      arg(:order_by, :service_group_order_by, default_value: :inserted_at_desc)

      resolve(&ServiceGroupResolver.load_sub_groups/3)
    end

    connection field(:services, node_type: :service) do
      arg(:filter, :service_filter)
      arg(:order_by, :service_order_by, default_value: :inserted_at_desc)

      resolve(&ServiceGroupResolver.load_services/3)
    end

    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end
end
