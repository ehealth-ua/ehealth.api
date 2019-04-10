defmodule GraphQL.Schema.EmployeeRequestTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  import GraphQL.Resolvers.EmployeeRequest, only: [resolve_data: 1]
  import GraphQL.Resolvers.Helpers.Load, only: [load_by_args: 2]

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.EmployeeRequests.EmployeeRequest
  alias GraphQL.Loaders.IL
  alias GraphQL.Middleware.Filtering
  alias GraphQL.Resolvers.EmployeeRequest, as: EmployeeRequestResolver

  object :employee_request_queries do
    connection field(:employee_requests, node_type: :employee_request) do
      meta(:scope, ~w(employee_request:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      arg(:filter, :employee_request_filter)
      arg(:order_by, :employee_request_order_by, default_value: :inserted_at_desc)
      middleware(ParseIDs, filter: [legal_entity_id: :legal_entity])

      middleware(Filtering,
        email: :equal,
        legal_entity_id: :equal,
        status: :equal,
        inserted_at: :in
      )

      resolve(&EmployeeRequestResolver.list_employee_requests/2)
    end

    field :employee_request, :employee_request do
      meta(:scope, ~w(employee_request:read))
      meta(:client_metadata, ~w(client_id client_type)a)
      meta(:allowed_clients, ~w(NHS))

      arg(:id, non_null(:id))
      middleware(ParseIDs, id: :employee_request)

      resolve(load_by_args(IL, EmployeeRequest))
    end
  end

  input_object :employee_request_filter do
    field(:email, :string)
    field(:inserted_at, :datetime_interval)
    field(:status, :string)
    field(:legal_entity_id, :id)
  end

  enum :employee_request_order_by do
    value(:full_name_asc)
    value(:full_name_desc)
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:status_asc)
    value(:status_desc)
  end

  connection(node_type: :employee_request) do
    field :nodes, list_of(:employee_request) do
      resolve(fn _, %{source: conn} ->
        {:ok, Enum.map(conn.edges, & &1.node)}
      end)
    end

    edge(do: nil)
  end

  object :employee_request_mutations do
    payload field(:create_employee_request) do
      meta(:scope, ~w(employee_request:create))
      meta(:client_metadata, ~w(client_id client_type consumer_id)a)
      meta(:allowed_clients, ~w(NHS MSP PHARMACY MSP_PHARMACY))

      input do
        field(:signed_content, non_null(:signed_content))
      end

      output do
        field(:employee_request, :employee_request)
      end

      resolve(&EmployeeRequestResolver.create_employee_request/2)
    end
  end

  node object(:employee_request) do
    field(:database_id, non_null(:uuid))
    field(:birth_date, non_null(:string), resolve: resolve_data(~w(party birth_date)))
    field(:email, non_null(:string), resolve: resolve_data(~w(party email)))
    field(:employee_type, non_null(:string), resolve: resolve_data(~w(employee_type)))
    field(:first_name, non_null(:string), resolve: resolve_data(~w(party first_name)))
    field(:second_name, :string, resolve: resolve_data(~w(party second_name)))
    field(:last_name, non_null(:string), resolve: resolve_data(~w(party last_name)))
    field(:no_tax_id, :boolean, resolve: resolve_data(~w(party no_tax_id)))
    field(:status, non_null(:string))
    field(:tax_id, non_null(:string), resolve: resolve_data(~w(party tax_id)))
    field(:legal_entity, non_null(:legal_entity), resolve: &EmployeeRequestResolver.resolve_legal_entity/3)

    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end
end
