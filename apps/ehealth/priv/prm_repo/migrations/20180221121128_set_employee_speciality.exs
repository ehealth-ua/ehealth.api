defmodule EHealth.PRMRepo.Migrations.SetEmployeeSpeciality do
  @moduledoc false

  use Ecto.Migration
  import Ecto.Query
  alias Ecto.Adapters.SQL
  alias EHealth.Employees.Employee
  alias EHealth.Parties.Party
  alias EHealth.PRMRepo
  alias Ecto.UUID

  @disable_ddl_transaction true

  def change do
    set_speciality()
  end

  defp set_speciality do
    query = """
    SELECT DISTINCT ON (party_id) e.id, e.party_id, e.inserted_at, e.additional_info
    FROM employees e
    LEFT JOIN parties p on p.id = e.party_id
    WHERE e.additional_info != '{}' AND (
      p.educations IS NULL AND
      p.qualifications IS NULL AND
      p.specialities IS NULL AND
      p.science_degree IS NULL
    )
    ORDER  BY party_id, inserted_at DESC
    LIMIT 1000;
    """

    {:ok, %{rows: employees, num_rows: num_rows}} = SQL.query(PRMRepo, query)

    Enum.each(employees, fn [id, party_id, _inserted_at, info] ->
      {:ok, id} = UUID.load(id)
      {:ok, party_id} = UUID.load(party_id)
      specialities = Map.get(info, "specialities") || []
      speciality = Enum.find(specialities, &Map.get(&1, "speciality_officio"))

      PRMRepo.transaction(fn ->
        Employee
        |> where([e], e.id == ^id)
        |> PRMRepo.update_all(set: [speciality: speciality])

        educations = Map.get(info, "educations", [])
        qualifications = Map.get(info, "qualifications", [])
        science_degree = Map.get(info, "science_degree")

        Party
        |> where([p], p.id == ^party_id)
        |> PRMRepo.update_all(
          set: [
            educations: educations,
            qualifications: qualifications,
            specialities: Enum.map(specialities, &Map.delete(&1, "speciality_officio")),
            science_degree: science_degree
          ]
        )
      end)
    end)

    if num_rows >= 1000, do: set_speciality()
  end
end
