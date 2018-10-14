defmodule GraphQLWeb.Schema.LegalEntityMergeJobTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias GraphQLWeb.Resolvers.LegalEntityMergeJob

  object :legal_entity_merge_job_mutations do
    payload field(:merge_legal_entities) do
      meta(:scope, ~w(legal_entity:merge))

      input do
        field(:signed_content, non_null(:signed_content))
      end

      output do
        field(:legal_entity_merge_job, :legal_entity_merge_job)
      end

      resolve(&LegalEntityMergeJob.merge_legal_entities/2)
    end
  end

  node object(:legal_entity_merge_job) do
    field(:database_id, non_null(:id))
    field(:status, non_null(:legal_entity_merge_job_status))
    field(:started_at, non_null(:datetime))
    field(:ended_at, :datetime)
    field(:merged_to_legal_entity, non_null(:mergee_legal_entity_metadata))
    field(:merged_from_legal_entity, non_null(:mergee_legal_entity_metadata))
  end

  enum :legal_entity_merge_job_status do
    value(:failed, as: "failed")
    value(:failed_with_error, as: "failed_with_error")
    value(:pending, as: "pending")
    value(:processed, as: "processed")
  end

  object :mergee_legal_entity_metadata do
    field(:id, :string)
    field(:name, :string)
    field(:edrpou, :string)
  end
end
