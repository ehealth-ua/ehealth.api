defmodule GraphQL.Resolvers.MergeRequest do
  @moduledoc false

  import GraphQL.Resolvers.Helpers.Load, only: [response_to_ecto_struct: 2]

  alias Absinthe.Relay.Connection
  alias Core.ManualMerge.ManualMergeRequest
  alias Ecto.Changeset

  @rpc_worker Application.get_env(:core, :rpc_worker)

  @status_new ManualMergeRequest.status(:new)
  @status_postpone ManualMergeRequest.status(:postpone)

  def list_merge_requests(%{order_by: order_by} = args, %{context: %{consumer_id: consumer_id}}) do
    filter = get_filter_conditions(consumer_id)

    with {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []),
         params <- [filter, order_by, {offset, limit + 1}],
         {:ok, merge_requests} <- @rpc_worker.run("mpi", MPI.Rpc, :search_manual_merge_requests, params) do
      opts = [has_previous_page: offset > 0, has_next_page: length(merge_requests) > limit]
      merge_requests = Enum.map(merge_requests, &response_to_ecto_struct(ManualMergeRequest, &1))

      Connection.from_slice(Enum.take(merge_requests, limit), offset, opts)
    end
  end

  def get_merge_request_by_id(_parent, %{id: id}, %{context: %{consumer_id: consumer_id}}) do
    filter = get_filter_conditions(consumer_id, [{:id, :equal, id}])

    with {:ok, [merge_request]} <- @rpc_worker.run("mpi", MPI.Rpc, :search_manual_merge_requests, [filter]) do
      {:ok, response_to_ecto_struct(ManualMergeRequest, merge_request)}
    else
      _ -> {:ok, nil}
    end
  end

  def resolve_can_assign_new(_, %{context: %{consumer_id: consumer_id}}) do
    with {:ok, result} <- @rpc_worker.run("mpi", MPI.Rpc, :can_assign_new_manual_merge_request, [consumer_id]) do
      {:ok, result}
    end
  end

  def assign_merge_candidate(_, %{context: %{consumer_id: consumer_id}}) do
    with {:ok, merge_request} <- @rpc_worker.run("mpi", MPI.Rpc, :assign_manual_merge_candidate, [consumer_id]) do
      {:ok, %{merge_request: response_to_ecto_struct(ManualMergeRequest, merge_request)}}
    else
      {:error, %Changeset{} = changeset} -> {:error, {:conflict, changeset_to_message(changeset)}}
      error -> error
    end
  end

  def update_merge_request(%{id: id, status: status} = args, %{context: %{consumer_id: consumer_id}}) do
    args = [id, status, consumer_id, Map.get(args, :comment, nil)]

    with {:ok, merge_request} <- @rpc_worker.run("mpi", MPI.Rpc, :process_manual_merge_request, args) do
      {:ok, %{merge_request: response_to_ecto_struct(ManualMergeRequest, merge_request)}}
    end
  end

  defp get_filter_conditions(consumer_id, filter \\ []) do
    [{:assignee_id, :equal, consumer_id}, {:status, :in, [@status_new, @status_postpone]} | filter]
  end

  defp changeset_to_message(changeset) do
    changeset
    |> Changeset.traverse_errors(fn {message, _} -> message end)
    |> Map.values()
    |> List.flatten()
    |> hd()
  end
end
