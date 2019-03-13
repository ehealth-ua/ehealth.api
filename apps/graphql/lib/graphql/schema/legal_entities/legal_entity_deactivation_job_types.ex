defmodule GraphQL.Schema.LegalEntityDeactivationJobTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Absinthe.Relay.Node.ParseIDs
  alias GraphQL.Middleware.FilterArgument
  alias GraphQL.Resolvers.LegalEntityDeactivationJob, as: LegalEntityDeactivationJobResolver

  object :legal_entity_deactivation_job_queries do
    @desc "get list of Legal Entity deactivation jobs"
    connection field(:legal_entity_deactivation_jobs, node_type: :legal_entity_deactivation_job) do
      meta(:scope, ~w(legal_entity_deactivation_job:read))

      arg(:filter, :legal_entity_deactivation_job_filter)
      arg(:order_by, :legal_entity_deactivation_job_order_by, default_value: :started_at_desc)

      middleware(FilterArgument)
      resolve(&LegalEntityDeactivationJobResolver.list_jobs/2)
    end

    @desc "get one Legal Entity deactivation job by id"
    field :legal_entity_deactivation_job, :legal_entity_deactivation_job do
      meta(:scope, ~w(legal_entity_deactivation_job:read))

      arg(:id, non_null(:id))

      middleware(ParseIDs, id: :legal_entity_deactivation_job)
      resolve(&LegalEntityDeactivationJobResolver.get_by_id/3)
    end
  end

  object :legal_entity_deactivation_job_mutations do
    payload field(:deactivate_legal_entity) do
      meta(:scope, ~w(legal_entity:deactivate))

      input do
        field(:id, non_null(:id))
      end

      output do
        field(:legal_entity_deactivation_job, :legal_entity_deactivation_job)
      end

      middleware(ParseIDs, id: :legal_entity)
      resolve(&LegalEntityDeactivationJobResolver.deactivate_legal_entity/2)
    end
  end

  input_object :legal_entity_deactivation_job_filter do
    field(:status, :legal_entity_deactivation_job_status)
    field(:deactivated_legal_entity, :deactivated_legal_entity_filter)
  end

  input_object :deactivated_legal_entity_filter do
    field(:edrpou, :string)
  end

  enum :legal_entity_deactivation_job_order_by do
    value(:started_at_asc)
    value(:started_at_desc)
  end

  connection(node_type: :legal_entity_deactivation_job) do
    field :nodes, list_of(:legal_entity_deactivation_job) do
      resolve(fn _, %{source: conn} ->
        {:ok, Enum.map(conn.edges, & &1.node)}
      end)
    end

    edge(do: nil)
  end

  node object(:legal_entity_deactivation_job) do
    field(:database_id, non_null(:object_id))
    field(:status, non_null(:legal_entity_deactivation_job_status))
    field(:started_at, non_null(:datetime))
    field(:ended_at, :datetime)
    field(:result, :string)
    field(:deactivated_legal_entity, non_null(:mergee_legal_entity_metadata))
  end

  enum :legal_entity_deactivation_job_status do
    value(:failed, as: "failed")
    value(:failed_with_error, as: "failed_with_error")
    value(:pending, as: "pending")
    value(:processed, as: "processed")
  end
end
