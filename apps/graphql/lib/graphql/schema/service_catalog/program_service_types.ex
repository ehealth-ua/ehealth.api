defmodule GraphQL.Schema.ProgramServiceTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import Absinthe.Resolution.Helpers, only: [dataloader: 1]
  import GraphQL.Resolvers.Helpers.Load, only: [load_by_args: 2]

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.Services.ProgramService
  alias GraphQL.Loaders.PRM
  alias GraphQL.Middleware.Filtering
  alias GraphQL.Resolvers.ProgramService, as: ProgramServiceResolver

  object :program_service_queries do
    connection field(:program_services, node_type: :program_service) do
      meta(:scope, ~w(program_service:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      arg(:filter, :program_service_filter)
      arg(:order_by, :program_service_order_by, default_value: :inserted_at_desc)

      middleware(
        Filtering,
        database_id: :equal,
        is_active: :equal,
        request_allowed: :equal,
        medical_program: [
          database_id: :equal,
          name: :like,
          type: :equal,
          is_active: :equal
        ],
        service: [
          database_id: :equal,
          name: :like,
          code: :like,
          category: :like,
          is_active: :equal
        ],
        service_group: [
          database_id: :equal,
          name: :like,
          code: :like,
          is_active: :equal
        ]
      )

      resolve(&ProgramServiceResolver.list_program_services/2)
    end

    field(:program_service, :program_service) do
      meta(:scope, ~w(program_service:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      arg(:id, non_null(:id))

      middleware(ParseIDs, id: :program_service)

      resolve(load_by_args(PRM, ProgramService))
    end
  end

  input_object :program_service_filter do
    field(:database_id, :uuid)
    field(:is_active, :boolean)
    field(:request_allowed, :boolean)
    field(:medical_program, :medical_program_filter)
    field(:service, :service_filter)
    field(:service_group, :service_group_filter)
  end

  enum :program_service_order_by do
    value(:consumer_price_asc)
    value(:consumer_price_desc)
    value(:inserted_at_asc)
    value(:inserted_at_desc)
  end

  connection node_type: :program_service do
    field :nodes, list_of(:program_service) do
      resolve(fn _, %{source: conn} -> {:ok, Enum.map(conn.edges, & &1.node)} end)
    end

    edge(do: nil)
  end

  node object(:program_service) do
    field(:database_id, non_null(:uuid))
    field(:consumer_price, :float)
    field(:description, :string)
    field(:is_active, non_null(:boolean))
    field(:request_allowed, non_null(:boolean))
    field(:medical_program, non_null(:medical_program), resolve: dataloader(PRM))
    field(:service, :service, resolve: dataloader(PRM))
    field(:service_group, :service_group, resolve: dataloader(PRM))
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end
end
