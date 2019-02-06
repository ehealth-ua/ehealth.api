defmodule GraphQLWeb.Schema.MergeRequestTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Absinthe.Relay.Node.ParseIDs
  alias Core.ManualMerge.ManualMergeRequest
  alias GraphQLWeb.Middleware.CheckUserRole
  alias GraphQLWeb.Middleware.Filtering
  alias GraphQLWeb.Resolvers.MergeRequestResolver

  object :merge_request_queries do
    @desc "Get MergeRequests"
    connection field(:merge_requests, node_type: :merge_request) do
      meta(:scope, ~w(merge_request:read))
      meta(:client_metadata, ~w(client_id client_type consumer_id)a)
      meta(:allowed_clients, ~w(NHS))
      arg(:order_by, :merge_request_order_by)

      middleware(CheckUserRole, role: "NHS REVIEWER")
      middleware(Filtering, status: :equal)

      resolve(&MergeRequestResolver.list_merge_requests/2)
    end

    @desc "Get MergeRequest by id"
    field(:merge_request, :merge_request) do
      meta(:scope, ~w(merge_request:read))
      meta(:client_metadata, ~w(client_id client_type consumer_id)a)
      meta(:allowed_clients, ~w(NHS))
      arg(:id, non_null(:id))

      middleware(CheckUserRole, role: "NHS REVIEWER")
      middleware(ParseIDs, id: :merge_request)
      resolve(&MergeRequestResolver.get_merge_request_by_id/3)
    end
  end

  enum :merge_request_order_by do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:status_asc)
    value(:status_desc)
  end

  connection node_type: :merge_request do
    field :nodes, list_of(:merge_request) do
      resolve(fn
        _, %{source: conn} ->
          nodes = conn.edges |> Enum.map(& &1.node)
          {:ok, nodes}
      end)
    end

    # TODO: Add resolving logic
    field(:can_assign_new, non_null(:boolean), resolve: fn _, _ -> {:ok, true} end)
    edge(do: nil)
  end

  object :merge_request_mutations do
    payload field(:update_merge_request) do
      meta(:scope, ~w(merge_request:write))
      meta(:client_metadata, ~w(client_id client_type consumer_id)a)
      meta(:allowed_clients, ~w(NHS))

      input do
        field(:id, non_null(:id))
        field(:status, non_null(:string))
        field(:comment, :string)
      end

      output do
        field(:merge_request, :merge_request)
      end

      middleware(CheckUserRole, role: "NHS REVIEWER")
      middleware(ParseIDs, id: :merge_request)
      resolve(&MergeRequestResolver.update_merge_request/2)
    end
  end

  node object(:merge_request) do
    field(:database_id, non_null(:id))
    field(:status, non_null(:merge_request_status))
    field(:comment, :string)
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
    field(:manual_merge_candidate, non_null(:manual_merge_candidate))
  end

  enum :merge_request_status do
    value(:merge, as: ManualMergeRequest.status(:merge))
    value(:new, as: ManualMergeRequest.status(:new))
    value(:postpone, as: ManualMergeRequest.status(:postpone))
    value(:split, as: ManualMergeRequest.status(:split))
    value(:trash, as: ManualMergeRequest.status(:trash))
  end

  node object(:manual_merge_candidate) do
    field(:database_id, non_null(:id))
    field(:merge_candidate, non_null(:merge_candidate))
    field(:status, :manual_merge_candidate_status)
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end

  node object(:merge_candidate) do
    field(:database_id, non_null(:id))
    field(:person, non_null(:person))
    field(:master_person, non_null(:person))
  end

  enum :manual_merge_candidate_status do
    value(:new, as: "NEW")
    value(:processed, as: "PROCESSED")
  end
end
