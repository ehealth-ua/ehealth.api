defmodule EHealth.Repo.Migrations.DropEmployeeDoctors do
  use Ecto.Migration

  def change do
    alter table(:employees) do
      add(:additional_info, :jsonb, null: false, default: "{}")
    end

    execute("""
    UPDATE employees SET
    additional_info = doctor.json
    FROM (
      SELECT
        ed.employee_id, row_to_json(t) as json
      FROM (
        SELECT educations, qualifications, specialities, science_degree
        FROM employee_doctors
      ) as t,
      employee_doctors ed
    ) AS doctor
    WHERE id = doctor.employee_id
    """)

    drop(table(:employee_doctors))
  end
end
