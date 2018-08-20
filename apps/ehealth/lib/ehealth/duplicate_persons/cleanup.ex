defmodule EHealth.DuplicatePersons.Cleanup do
  @moduledoc false

  alias Core.Declarations.Person

  @mpi_api Application.get_env(:core, :api_resolvers)[:mpi]
  @ops_api Application.get_env(:core, :api_resolvers)[:ops]

  def cleanup(id, person_id) do
    {:ok, %{"data" => declarations}} =
      @ops_api.get_declarations(
        %{
          person_id: person_id,
          is_active: true
        },
        []
      )

    Enum.each(declarations, fn declaration ->
      @ops_api.terminate_person_declarations(declaration["person_id"], system_user_id(), "auto_merge", "", [])
    end)

    {:ok, %{"data" => _}} = @mpi_api.update_merge_candidate(id, %{status: Person.status(:merged)}, headers())
    {:ok, %{"data" => _}} = @mpi_api.update_person(person_id, %{status: Person.status(:inactive)}, headers())
  end

  def update_master_merged_ids(master_person_id, duplicate_person_ids) do
    {:ok, %{"data" => _}} = @mpi_api.update_person(master_person_id, %{merged_ids: duplicate_person_ids}, headers())
  end

  defp system_user_id, do: Confex.fetch_env!(:core, :system_user)

  defp headers, do: [{"x-consumer-id", system_user_id()}]
end
