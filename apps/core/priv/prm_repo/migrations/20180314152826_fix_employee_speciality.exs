defmodule Core.PRMRepo.Migrations.FixEmployeeSpeciality do
  @moduledoc false

  use Ecto.Migration
  import Ecto.Query
  alias Ecto.Adapters.SQL
  alias Core.Parties.Party
  alias Core.PRMRepo
  alias Ecto.UUID

  def change do
    query = """
    with ad_ AS (
      SELECT
        e.*,
        al.id,
        json_extract_path_text((al.changeset :: JSON), 'status') AS change_status,
        al.inserted_at change_inserted_at
      FROM employees e LEFT JOIN audit_log al ON e.id = uuid(al.resource_id)
      WHERE e.additional_info <> '{}'
    ),
    ad_2 AS (
        SELECT party_id, max(change_inserted_at) max_change_inserted_at
        FROM ad_
        WHERE change_status <> 'DISMISSED'
        group by party_id
    )
    SELECT
      a.party_id,
      additional_info
    FROM ad_ a JOIN ad_2 b ON a.change_inserted_at = b.max_change_inserted_at AND a.party_id = b.party_id
    """

    {:ok, %{rows: data, num_rows: num_rows}} = SQL.query(PRMRepo, query)

    Enum.each(data, fn [party_id, info] ->
      {:ok, id} = UUID.load(party_id)
      specialities = Map.get(info, "specialities") || []

      PRMRepo.transaction(fn ->
        educations = Map.get(info, "educations", [])
        qualifications = Map.get(info, "qualifications", [])
        science_degree = Map.get(info, "science_degree")

        Party
        |> where([p], p.id == ^id)
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
  end
end
