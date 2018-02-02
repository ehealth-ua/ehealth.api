defmodule EHealth.DuplicatePersons.Cleanup do
  @moduledoc false

  alias EHealth.API.OPS
  alias EHealth.API.MPI
  alias EHealth.Declarations.Person

  @system_consumer_id Confex.fetch_env!(:ehealth, :system_user)

  def cleanup(id, person_id) do
    {:ok, %{"data" => declarations}} =
      OPS.get_declarations(%{
        person_id: person_id,
        is_active: true
      })

    Enum.each(declarations, fn declaration ->
      user_id = Confex.fetch_env!(:ehealth, :system_user)
      OPS.terminate_person_declarations(declaration["person_id"], user_id, "auto_merge")
    end)

    {:ok, %{"data" => _}} = MPI.update_merge_candidate(id, %{status: Person.status(:merged)})
    {:ok, %{"data" => _}} = MPI.update_person(person_id, %{status: Person.status(:inactive)}, headers())
  end

  def update_master_merged_ids(master_person_id, duplicate_person_ids) do
    {:ok, %{"data" => _}} = MPI.update_person(master_person_id, %{merged_ids: duplicate_person_ids}, headers())
  end

  defp headers do
    [{"x-consumer-id", @system_consumer_id}]
  end
end
