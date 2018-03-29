defmodule EHealth.PRMRepo.Migrations.SetAdditionalInfoSpecialityOfficio do
  @moduledoc false

  use Ecto.Migration
  import Ecto.Query
  alias Ecto.Adapters.SQL
  alias Ecto.UUID
  alias EHealth.Employees.Employee
  alias EHealth.PRMRepo

  def change do
    query = """
    with t1 as(
      select   id, additional_info
              ,json_extract_path_text(json_array_elements(json_extract_path_text(additional_info::json, 'specialities')::json),'speciality_officio') as speciality_officio
              ,json_extract_path_text(json_array_elements(json_extract_path_text(additional_info::json, 'specialities')::json),'speciality') as speciality
              ,inserted_at
      from employees
      where employee_type='DOCTOR'
      ),
        t2 as(
      select id,
             inserted_at,
             max(case when speciality_officio='true' then 1 else 0 end) as s_true,
             max(case when speciality_officio='false' then 1 else 0 end) as s_false,
             count(*) qty
      from t1 a
      group by id, inserted_at
      ),
        t3 as(
      select b.*, qty
      from t2 a join t1 b on a.id=b.id
      where s_false=1 and s_true=0
        ),
        t4 as(
      select  a.id,
              additional_info
             ,qty
             ,max(case when speciality='PEDIATRICIAN' then 1 else 0 end) as PEDIATRICIAN
             ,max(case when speciality='THERAPIST' then 1 else 0 end) as THERAPIST
             ,max(case when speciality='FAMILY_DOCTOR' then 1 else 0 end) as FAMILY_DOCTOR
      from t3 a
      group by a.id
              ,additional_info
              ,qty
        )
      select  id, additional_info
             ,case when qty=1 and PEDIATRICIAN=1 then 'PEDIATRICIAN'
                   when qty=1 and THERAPIST=1 then 'THERAPIST'
                   when qty=1 and FAMILY_DOCTOR=1 then 'FAMILY_DOCTOR'
                   when qty>1 and FAMILY_DOCTOR=1 then 'FAMILY_DOCTOR'
                   when qty>1 and THERAPIST=1 then 'THERAPIST'
                   when qty>1 and PEDIATRICIAN=1 then 'PEDIATRICIAN'
              end as speciality_officio
      from t4;
    """

    {:ok, %{rows: employees, num_rows: num_rows}} = SQL.query(PRMRepo, query)

    Enum.each(employees, fn [id, info, speciality_officio_name] ->
      {:ok, id} = UUID.load(id)
      specialities = Map.get(info, "specialities") || []
      specialities = specialities |> Enum.with_index() |> Enum.map(fn {v, i} -> {i, v} end) |> Enum.into(%{})

      {speciality_officio, index} =
        Enum.find(specialities, fn {i, speciality} ->
          Map.get(speciality, "speciality") == speciality_officio_name
        end)

      specialities = Map.put(specialities, index, Map.put(speciality_officio, "speciality_officio", true))
      additional_info = Map.put(info, "specialities", specialities)

      Employee
      |> where([e], e.id == ^id)
      |> PRMRepo.update_all(set: [additional_info: additional_info])
    end)
  end
end
