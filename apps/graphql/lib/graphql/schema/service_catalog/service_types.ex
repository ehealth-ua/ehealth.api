defmodule GraphQL.Schema.ServiceTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import GraphQL.Resolvers.Helpers.Load, only: [load_by_args: 2]

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.Services.Service
  alias GraphQL.Loaders.PRM
  alias GraphQL.Middleware.Filtering
  alias GraphQL.Resolvers.Service, as: ServiceResolver

  object :service_queries do
    @desc "Get all services"
    connection field(:services, node_type: :service) do
      meta(:scope, ~w(service_catalog:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      arg(:filter, :service_filter)
      arg(:order_by, :service_order_by, default_value: :inserted_at_desc)

      middleware(Filtering,
        database_id: :equal,
        name: :like,
        code: :like,
        category: :like,
        is_active: :equal
      )

      resolve(&ServiceResolver.list_services/2)
    end

    @desc "Get service by id"
    field(:service, :service) do
      meta(:scope, ~w(service_catalog:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      arg(:id, non_null(:id))

      middleware(ParseIDs, id: :service)
      resolve(load_by_args(PRM, Service))
    end
  end

  input_object :service_filter do
    field(:database_id, :uuid)
    field(:code, :string)
    field(:name, :string)
    field(:is_active, :boolean)
    field(:category, :string)
  end

  enum :service_order_by do
    value(:code_asc)
    value(:code_desc)
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:name_asc)
    value(:name_desc)
  end

  connection(node_type: :service) do
    field :nodes, list_of(:service) do
      resolve(fn _, %{source: conn} ->
        {:ok, Enum.map(conn.edges, & &1.node)}
      end)
    end

    edge(do: nil)
  end

  object :service_mutations do
    payload field(:create_service) do
      meta(:scope, ~w(service_catalog:write))
      meta(:client_metadata, ~w(client_id client_type consumer_id)a)
      meta(:allowed_clients, ~w(NHS))

      input do
        field(:name, non_null(:string))
        field(:code, non_null(:string))
        field(:is_composition, :boolean)
        field(:request_allowed, :boolean)
        field(:category, :string)
      end

      output do
        field(:service, :service)
      end

      resolve(&ServiceResolver.create/2)
    end

    payload field(:update_service) do
      meta(:scope, ~w(service_catalog:write))
      meta(:client_metadata, ~w(consumer_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      input do
        field(:id, non_null(:id))
        field(:request_allowed, :boolean)
      end

      output do
        field(:service, :service)
      end

      middleware(ParseIDs, id: :service)
      resolve(&ServiceResolver.update/2)
    end

    payload field(:deactivate_service) do
      meta(:scope, ~w(service_catalog:write))
      meta(:client_metadata, ~w(consumer_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      input do
        field(:id, non_null(:id))
      end

      output do
        field(:service, :service)
      end

      middleware(ParseIDs, id: :service)
      resolve(&ServiceResolver.deactivate/2)
    end
  end

  node object(:service) do
    field(:database_id, non_null(:uuid))
    field(:code, non_null(:string))
    field(:name, non_null(:string))
    # Dictionary: SERVICE_CATEGORY
    field(:category, :string)
    field(:is_active, non_null(:boolean))
    field(:is_composition, :boolean)
    field(:request_allowed, :boolean)

    # relations
    connection field(:service_groups, node_type: :service_group) do
      arg(:filter, :service_group_filter)
      arg(:order_by, :service_group_order_by, default_value: :inserted_at_asc)

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

      resolve(&ServiceResolver.load_service_groups/3)
    end

    # timestamps
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end
end
