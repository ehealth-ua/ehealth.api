defmodule EHealth.DuplicatePersons.Cleanup do
  @moduledoc false

  alias EHealth.API.OPS
  alias EHealth.API.MPI

  def cleanup(merge_candidate_id) do
    {:ok, %{"data" => declarations}} =
      OPS.get_declarations(%{
        person_id: merge_candidate_id,
        is_active: true
      })

    Enum.each declarations, fn declaration ->
      OPS.terminate_person_declarations(declaration["person_id"])
    end

    {:ok, %{"data" => _}} = MPI.update_merge_candidate(merge_candidate_id, %{status: "MERGED"})
  end
end
