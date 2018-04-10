defmodule EHealth.Repo.Migrations.FixEmployeeRequestSpecialities do
  @moduledoc false

  use Ecto.Migration
  import Ecto.Query
  alias Ecto.Adapters.SQL
  alias EHealth.Repo
  alias Ecto.UUID
  alias EHealth.EmployeeRequests.EmployeeRequest

  @disable_ddl_transaction true

  def change do
    query = """
      with t1 as(
        select id, data,
                  json_extract_path_text(data :: JSON, 'employee_type') AS employee_type,
                  json_extract_path_text(json_array_elements(json_extract_path(json_extract_path(data :: JSON, 'doctor') :: JSON, 'specialities')),'speciality_officio') AS speciality_officio,
                  json_extract_path_text(json_array_elements(json_extract_path(json_extract_path(data :: JSON, 'doctor') :: JSON, 'specialities')),'speciality')         AS speciality
        from employee_requests
        where status='NEW'
        ),
          t2 as(
        select id, data,
              max(case when speciality_officio='true' then 1 else 0 end) as s_true,
              sum(case when speciality_officio='true' then 1 else 0 end) as sum_s_true,
              max(case when speciality_officio='false' then 1 else 0 end) as s_false,
              count(*) qty
        from t1 a
        where 1=1
          and employee_type='DOCTOR'
        group by id, data
        ),
          t3 as(
        select b.*, qty
        from t2 a join t1 b on a.id=b.id
        where (s_false=1 and s_true=0) or sum_s_true>1
          ),
          t4 as(
        select  a.id
              ,data
              ,qty
              ,max(case when speciality='PEDIATRICIAN' then 1 else 0 end) as PEDIATRICIAN
              ,max(case when speciality='THERAPIST' then 1 else 0 end) as THERAPIST
              ,max(case when speciality='FAMILY_DOCTOR' then 1 else 0 end) as FAMILY_DOCTOR
        from t3 a
        group by a.id
                ,data
                ,qty
          )
        select  id
              ,case when qty=1 and PEDIATRICIAN=1 then 'PEDIATRICIAN'
                    when qty=1 and THERAPIST=1 then 'THERAPIST'
                    when qty=1 and FAMILY_DOCTOR=1 then 'FAMILY_DOCTOR'
                    when qty>1 and FAMILY_DOCTOR=1 then 'FAMILY_DOCTOR'
                    when qty>1 and THERAPIST=1 then 'THERAPIST'
                    when qty>1 and PEDIATRICIAN=1 then 'PEDIATRICIAN'
                end as speciality_officio
              , data
        from t4
    """

    {:ok, %{rows: data, num_rows: num_rows}} = SQL.query(Repo, query)

    Enum.each(data, fn [id, speciality_officio, data] ->
      {:ok, id} = UUID.load(id)
      specialities = get_in(data, ~w(doctor specialities))

      {specialities, _} =
        specialities
        |> Enum.map(&Map.put(&1, "speciality_officio", false))
        |> Enum.reduce({[], false}, fn speciality, acc ->
          set_speciality_officio(speciality_officio, speciality, acc)
        end)

      new_data = put_in(data, ~w(doctor specialities), specialities)

      EmployeeRequest
      |> where([p], p.id == ^id)
      |> Repo.update_all(
        set: [
          data: new_data
        ]
      )
    end)
  end

  defp set_speciality_officio(speciality_officio, speciality, {acc, is_set}) do
    is_officio = speciality["speciality"] == speciality_officio

    if is_set do
      {acc ++ [Map.put(speciality, "speciality_officio", false)], is_set}
    else
      {acc ++ [Map.put(speciality, "speciality_officio", is_officio)], is_officio}
    end
  end
end
