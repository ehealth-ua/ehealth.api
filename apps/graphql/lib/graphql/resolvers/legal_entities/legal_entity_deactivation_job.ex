defmodule GraphQL.Resolvers.LegalEntityDeactivationJob do
  @moduledoc false

  alias Absinthe.Relay.Connection
  alias Absinthe.Relay.Node
  alias Jobs.LegalEntityDeactivationJob
  alias TasKafka.Job

  @legal_entity_deactivation_type Jobs.type(:legal_entity_deactivation)

  def deactivate_legal_entity(%{id: id}, %{context: %{headers: headers}}) do
    case LegalEntityDeactivationJob.create(id, headers) do
      {:ok, %Job{} = job} ->
        {:ok, %{legal_entity_deactivation_job: job_view(job)}}

      {:job_exists, id} ->
        id = Node.to_global_id("LegalEntityDeactivationJob", id)
        {:error, {:conflict, "Legal Entity deactivation job is already created with id #{id}"}}

      err ->
        err
    end
  end

  def list_jobs(%{filter: filter, order_by: order_by} = args, _resolution) do
    with {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []) do
      records =
        filter
        |> Jobs.list(limit, offset, order_by, @legal_entity_deactivation_type)
        |> job_view()

      opts = [has_previous_page: offset > 0, has_next_page: length(records) > limit]

      Connection.from_slice(Enum.take(records, limit), offset, opts)
    end
  end

  def get_by_id(_parent, %{id: id}, _resolution) do
    case Jobs.get_by_id(id) do
      {:ok, job} -> {:ok, job_view(job)}
      nil -> {:ok, nil}
    end
  end

  defp job_view(%Job{} = job), do: Jobs.view(job, [:deactivated_legal_entity])
  defp job_view([]), do: []
  defp job_view(jobs) when is_list(jobs), do: Enum.map(jobs, &job_view/1)
end
