defmodule GraphQL.Resolvers.LegalEntityMergeJob do
  @moduledoc false

  alias Absinthe.Relay.Connection
  alias Jobs.LegalEntityMergeJob

  def merge_legal_entities(args, resolution) do
    case LegalEntityMergeJob.create(args, resolution.context.headers) do
      {:ok, job} -> {:ok, %{legal_entity_merge_job: job}}
      err -> err
    end
  end

  def search_jobs(%{filter: filter, order_by: order_by} = args, _resolution) do
    with {:ok, offset, limit} <- Connection.offset_and_limit_for_query(args, []),
         {:ok, records} <- LegalEntityMergeJob.search_jobs(filter, order_by, limit + 1, offset) do
      opts = [has_previous_page: offset > 0, has_next_page: length(records) > limit]

      Connection.from_slice(Enum.take(records, limit), offset, opts)
    end
  end

  def get_by_id(_parent, %{id: id}, _resolution) do
    case LegalEntityMergeJob.get_job(id) do
      {:ok, _} = response -> response
      nil -> {:ok, nil}
    end
  end
end
