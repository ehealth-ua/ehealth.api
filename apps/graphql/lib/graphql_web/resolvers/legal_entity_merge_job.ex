defmodule GraphQLWeb.Resolvers.LegalEntityMergeJob do
  @moduledoc false

  alias BSON.ObjectId
  alias Core.Jobs
  alias Core.Utils.TypesConverter
  alias TasKafka.Job
  alias TasKafka.Jobs, as: TasKafkaJobs

  def merge_legal_entities(args, resolution) do
    with {:ok, %Job{} = job} <- Jobs.create_merge_legal_entities_job(args, resolution.context.headers) do
      {:ok, %{legal_entity_merge_job: job_view(job)}}
    end
  end

  def list_jobs(_args, _resolution) do
    # ToDo: taskafka is not supported list of jobs yet
    {:ok, []}
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
      started_at: job.started_at,
      ended_at: job.ended_at
    }
  end
end
