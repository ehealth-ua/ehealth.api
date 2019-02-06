defmodule Core.ManualMerge.ManualMergeCandidate do
  @moduledoc false

  use Ecto.Schema

  alias Core.ManualMerge.MergeCandidate
  alias Ecto.UUID

  embedded_schema do
    field(:status, :string)
    field(:decision, :string)
    field(:assignee_id, UUID)
    field(:person_id, UUID)
    field(:master_person_id, UUID)
    belongs_to(:merge_candidate, MergeCandidate)

    timestamps(type: :utc_datetime)
  end
end
