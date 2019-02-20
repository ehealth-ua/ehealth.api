defmodule Core.PRMRepo.Migrations.TerminateEmployeeDeclarationsFix do
  @moduledoc false

  use Ecto.Migration
  import Ecto.Query
  alias Core.Employees.Employee
  alias Core.Kafka.Producer
  alias Core.PRMRepo

  def change do
    Application.ensure_all_started(:kafka_ex)

    from(
      e in Employee,
      where: e.status == ^Employee.status(:dismissed),
      where: e.updated_at >= ^DateTime.from_naive!(~N[2019-01-11 00:00:00], "Etc/UTC")
    )
    |> select([e], %{"employee_id" => e.id, "actor_id" => e.updated_by, "reason" => "auto_employee_deactivate"})
    |> PRMRepo.all()
    |> Enum.each(fn e -> :ok = Producer.publish_deactivate_declaration_event(e) end)
  end
end
