defmodule GraphQLWeb.Schema.LegalEntityMergeJobTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Absinthe.Relay.Node.ParseIDs
  alias GraphQLWeb.Resolvers.LegalEntityMergeJobResolver

  object :legal_entity_merge_job_queries do
    @desc "get list of Legal Entities merge jobs"
    connection field(:legal_entity_merge_jobs, node_type: :legal_entity_merge_job) do
      meta(:scope, ~w(legal_entity_merge_job:read))

      arg(:filter, :legal_entity_merge_job_filter)
      arg(:order_by, :legal_entity_merge_job_order_by, default_value: :started_at_desc)

      # TODO: Replace it with `GraphQLWeb.Middleware.Filtering`
      middleware(GraphQLWeb.Middleware.FilterArgument)
      resolve(&LegalEntityMergeJobResolver.list_jobs/2)
    end

    @desc "get one Legal Entity merge job by id"
    field :legal_entity_merge_job, :legal_entity_merge_job do
      meta(:scope, ~w(legal_entity_merge_job:read))

      arg(:id, non_null(:id))

      middleware(ParseIDs, id: :legal_entity_merge_job)
      resolve(&LegalEntityMergeJobResolver.get_by_id/3)
    end
  end

  object :legal_entity_merge_job_mutations do
    payload field(:merge_legal_entities) do
      meta(:scope, ~w(legal_entity:merge))

      input do
        field(:signed_content, non_null(:signed_content))
      end

      output do
        field(:legal_entity_merge_job, :legal_entity_merge_job)
      end

      resolve(&LegalEntityMergeJobResolver.merge_legal_entities/2)
    end
  end

  input_object :legal_entity_merge_job_filter do
    field(:status, :legal_entity_merge_job_status)
    field(:merged_to_legal_entity, :mergee_legal_entity_filter)
    field(:merged_from_legal_entity, :mergee_legal_entity_filter)
  end

  input_object :mergee_legal_entity_filter do
    field(:edrpou, :string)
    field(:is_active, :boolean)
  end

  enum :legal_entity_merge_job_order_by do
    value(:started_at_asc)
    value(:started_at_desc)
  end

  connection(node_type: :legal_entity_merge_job) do
    field :nodes, list_of(:legal_entity_merge_job) do
      resolve(fn _, %{source: conn} ->
        {:ok, Enum.map(conn.edges, & &1.node)}
      end)
    end

    edge(do: nil)
  end

  node object(:legal_entity_merge_job) do
    field(:database_id, non_null(:id))
    field(:status, non_null(:legal_entity_merge_job_status))
    field(:started_at, non_null(:datetime))
    field(:ended_at, :datetime)
    field(:result, :string)
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
