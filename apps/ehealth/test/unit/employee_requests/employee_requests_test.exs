defmodule EHealth.Unit.EmployeeRequestsTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  import Ecto.Query
  alias EHealth.EmployeeRequests
  alias EHealth.EmployeeRequests.EmployeeRequest, as: Request
  alias EHealth.EventManagerRepo
  alias EHealth.EventManager.Event
  alias EHealth.Repo
  alias Ecto.UUID

  test "terminate outdated employee_requests" do
    employee_id = UUID.generate()
    employee_request1 = insert(:il, :employee_request, employee_id: employee_id)
    employee_request2 = insert(:il, :employee_request)
    insert(:il, :employee_request)
    inserted_at = NaiveDateTime.add(NaiveDateTime.utc_now(), -86_400 * 10, :seconds)

    employee_request1
    |> Ecto.Changeset.change(inserted_at: inserted_at)
    |> Repo.update()

    employee_request2
    |> Ecto.Changeset.change(inserted_at: inserted_at)
    |> Repo.update()

    assert 3 = Request |> Repo.all() |> Enum.count()

    insert(:prm, :global_parameter, parameter: "employee_request_term_unit", value: "DAYS")
    insert(:prm, :global_parameter, parameter: "employee_request_expiration", value: "5")

    EmployeeRequests.terminate_employee_requests()

    request_id = employee_request1.id
    expired_status = Request.status(:expired)
    assert %{status: ^expired_status} = Repo.get(Request, request_id)

    assert [event1, _event2] =
             Event
             |> order_by([e], e.inserted_at)
             |> EventManagerRepo.all()

    assert %Event{
             entity_type: "EmployeeRequest",
             event_type: "StatusChangeEvent",
             entity_id: ^request_id,
             properties: %{
               "status" => %{"new_value" => ^expired_status},
               "employee_id" => %{"new_value" => ^employee_id}
             }
           } = event1
  end
end
