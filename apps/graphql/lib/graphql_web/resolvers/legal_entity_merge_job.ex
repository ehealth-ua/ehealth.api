defmodule GraphQLWeb.Resolvers.LegalEntityMergeJob do
  @moduledoc false

  alias BSON.ObjectId
  alias Core.Jobs
  alias Core.Utils.TypesConverter
  alias TasKafka.Job

  def merge_legal_entities(args, resolution) do
    with {:ok, %Job{} = job} <- Jobs.create_merge_legal_entities_job(args, resolution.context.headers) do
      meta = TypesConverter.strings_to_keys(job.meta)

      legal_entity_merge_job = %{
        id: ObjectId.encode!(job._id),
        status: Job.status_to_string(job.status),
        merged_from_legal_entity: meta.merged_from_legal_entity,
        merged_to_legal_entity: meta.merged_to_legal_entity,
        started_at: job.started_at
      }

      {:ok, %{legal_entity_merge_job: legal_entity_merge_job}}
    end
  end
end
