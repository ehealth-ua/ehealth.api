defmodule Core.MPIFactories.ManualMergeFactory do
  @moduledoc false

  alias Ecto.UUID

  defmacro __using__(_opts) do
    quote do
      def manual_merge_request_factory do
        now = DateTime.utc_now()

        %{
          id: UUID.generate(),
          status: "NEW",
          comment: "comment",
          assignee_id: UUID.generate(),
          manual_merge_candidate_id: UUID.generate(),
          manual_merge_candidate: nil,
          inserted_at: now,
          updated_at: now
        }
      end

      def manual_merge_candidate_factory do
        now = DateTime.utc_now()

        %{
          id: UUID.generate(),
          status: "NEW",
          decision: nil,
          assignee_id: nil,
          person_id: UUID.generate(),
          master_person_id: UUID.generate(),
          merge_candidate: nil,
          merge_candidate_id: UUID.generate(),
          inserted_at: now,
          updated_at: now
        }
      end

      def merge_candidate_factory do
        %{
          id: UUID.generate(),
          status: "NEW",
          config: %{},
          person: build(:person),
          master_person: build(:person),
          score: 0.8
        }
      end
    end
  end
end
