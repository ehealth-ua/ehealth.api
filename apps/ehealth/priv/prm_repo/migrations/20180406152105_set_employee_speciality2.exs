defmodule EHealth.PRMRepo.Migrations.SetEmployeeSpeciality2 do
  @moduledoc false

  use Ecto.Migration
  import Ecto.Query
  alias Ecto.Adapters.SQL
  alias EHealth.Employees.Employee
  alias EHealth.PRMRepo
  alias Ecto.UUID

  @disable_ddl_transaction true

  def change do
    set_employee_speciality()
  end

  defp set_employee_speciality do
    query = """
    SELECT e.id, e.additional_info
    FROM employees e
    WHERE e.additional_info != '{}' AND e.speciality IS NULL
    ORDER BY inserted_at ASC
    LIMIT 1000;
    """

    {:ok, %{rows: employees, num_rows: num_rows}} = SQL.query(PRMRepo, query)

    Enum.each(employees, fn [id, info] ->
      {:ok, id} = UUID.load(id)
      specialities = Map.get(info, "specialities") || []
      speciality = Enum.find(specialities, &Map.get(&1, "speciality_officio"))

      Employee
      |> where([e], e.id == ^id)
      |> PRMRepo.update_all(set: [speciality: speciality])
    end)

    if num_rows >= 1000, do: set_employee_speciality()
  end
end
