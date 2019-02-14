defmodule GraphQLWeb.Resolvers.LegalEntityMergeJobResolver do
  @moduledoc false

  alias Absinthe.Relay.Connection
  alias Absinthe.Relay.Node
  alias Jobs.LegalEntityMergeJob
  alias TasKafka.Job

  @type_merge_legal_entities Jobs.type(:merge_legal_entities)

  def merge_legal_entities(args, resolution) do
    case LegalEntityMergeJob.create(args, resolution.context.headers) do
      {:ok, %Job{} = job} ->
        {:ok, %{legal_entity_merge_job: job_view(job)}}

      {:job_exists, id} ->
        id = Node.to_global_id("LegalEntityMergeJob", id)
        {:error, {:conflict, "Merge Legal Entity job is already created with id #{id}"}}

      err ->
        err
    end
  end

  def list_jobs(%{filter: filter, order_by: order_by} = args, _resolution) do
    {:ok, :forward, limit} = Connection.limit(args)

    offset =
      case Connection.offset(args) do
        {:ok, offset} when is_integer(offset) -> offset
        _ -> 0
      end

    records =
      filter
      |> Jobs.list(limit, offset, order_by, @type_merge_legal_entities)
      |> job_view()

    opts = [has_previous_page: offset > 0, has_next_page: length(records) > limit]

    Connection.from_slice(Enum.take(records, limit), offset, opts)
  end

  def get_by_id(_parent, %{id: id}, _resolution) do
    case Jobs.get_by_id(id) do
      {:ok, job} -> {:ok, job_view(job)}
      nil -> {:ok, nil}
    end
  end

  defp job_view(%Job{} = job), do: Jobs.view(job, [:merged_to_legal_entity, :merged_from_legal_entity])
  defp job_view([]), do: []
  defp job_view(jobs) when is_list(jobs), do: Enum.map(jobs, &job_view/1)
end
