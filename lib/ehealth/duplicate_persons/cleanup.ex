defmodule EHealth.DuplicatePersons.Cleanup do
  @moduledoc false

  alias EHealth.API.OPS
  alias EHealth.API.MPI

  def cleanup(id, person_id) do
    {:ok, %{"data" => declarations}} =
      OPS.get_declarations(%{
        person_id: person_id,
        is_active: true
      })

    Enum.each declarations, fn declaration ->
      OPS.terminate_person_declarations(declaration["person_id"])
    end

    {:ok, %{"data" => _}} = MPI.update_merge_candidate(id, %{status: "MERGED"})
    {:ok, %{"data" => _}} = MPI.update_person(person_id, %{status: "INACTIVE"})
  end

  def update_master_merged_ids(master_person_id, duplicate_person_ids) do
    {:ok, %{"data" => _}} = MPI.update_person(master_person_id, %{merged_ids: duplicate_person_ids})
  end
end
