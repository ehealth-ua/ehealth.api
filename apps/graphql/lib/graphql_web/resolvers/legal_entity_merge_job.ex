defmodule GraphQLWeb.Resolvers.LegalEntityMergeJob do
  @moduledoc false

  alias Absinthe.Relay.Connection
  alias BSON.ObjectId
  alias Core.Jobs
  alias Core.Utils.TypesConverter
  alias TasKafka.Job
  alias TasKafka.Jobs, as: TasKafkaJobs

  @type_merge_legal_entities Jobs.type(:merge_legal_entities)

  def merge_legal_entities(args, resolution) do
    with {:ok, %Job{} = job} <- Jobs.create_merge_legal_entities_job(args, resolution.context.headers) do
      {:ok, %{legal_entity_merge_job: job_view(job)}}
    end
  end

  def list_jobs(%{filter: filter, order_by: order_by} = args, _resolution) do
    {:ok, :forward, limit} = Connection.limit(args)

    offset =
      case Connection.offset(args) do
        {:ok, offset} when is_integer(offset) -> offset
        _ -> 0
      end

    opts = [limit: limit + 1, skip: offset, sort: prepare_order_by(order_by)]

    records =
      filter
      |> Enum.reduce(%{}, &prepare_mongo_filter/2)
      |> Map.put("type", @type_merge_legal_entities)
      |> TasKafkaJobs.get_list(opts)
      |> job_view()

    opts = [has_previous_page: offset > 0, has_next_page: length(records) > limit]

    Connection.from_slice(Enum.take(records, limit), offset, opts)
  end

  def get_by_id(_parent, %{id: id}, _resolution) do
    with {:ok, job} <- TasKafkaJobs.get_by_id(id) do
      {:ok, job_view(job)}
    end
  end

  defp job_view(%Job{} = job) do
    meta = TypesConverter.strings_to_keys(job.meta)

    %{
      id: ObjectId.encode!(job._id),
      status: Job.status_to_string(job.status),
      merged_from_legal_entity: meta.merged_from_legal_entity,
      merged_to_legal_entity: meta.merged_to_legal_entity,
      result: Jason.encode!(job.result),
      started_at: job.started_at,
      ended_at: job.ended_at
    }
  end

  defp job_view([]), do: []
  defp job_view(jobs) when is_list(jobs), do: Enum.map(jobs, &job_view/1)

  def prepare_mongo_filter({:status, value}, acc) do
    Map.put(acc, "status", value |> String.to_atom() |> Job.status())
  end

  def prepare_mongo_filter({key, filters}, acc) when key in [:merged_to_legal_entity, :merged_from_legal_entity] do
    Enum.reduce(filters, acc, fn {filter, value}, acc ->
      Map.put(acc, "meta.#{key}.#{filter}", value)
    end)
  end

  defp prepare_order_by([]), do: nil
  defp prepare_order_by([{:asc, field}]), do: %{Atom.to_string(field) => 1}
  defp prepare_order_by([{:desc, field}]), do: %{Atom.to_string(field) => -1}
end
