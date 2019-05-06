defmodule Core.ManualMerge.ManualMergeRequest do
  @moduledoc false

  use Ecto.Schema
  alias Core.ManualMerge.ManualMergeCandidate

  @status_new "NEW"
  @status_split "SPLIT"
  @status_merge "MERGE"
  @status_trash "TRASH"
  @status_postpone "POSTPONE"

  embedded_schema do
    field(:status, :string)
    field(:comment, :string)
    field(:assignee_id, Ecto.UUID)
    belongs_to(:manual_merge_candidate, ManualMergeCandidate)

    timestamps(type: :utc_datetime_usec)
  end

  def status(:new), do: @status_new
  def status(:split), do: @status_split
  def status(:merge), do: @status_merge
  def status(:trash), do: @status_trash
  def status(:postpone), do: @status_postpone
end
