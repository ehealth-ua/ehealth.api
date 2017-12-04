defmodule EHealth.Integration.EmployeeRequest.TerminatorTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  alias EHealth.EmployeeRequest.Terminator
  alias EHealth.EmployeeRequests.EmployeeRequest, as: Request
  alias EHealth.EventManagerRepo
  alias EHealth.EventManager.Event
  alias EHealth.Repo

  @tag :pending
  test "start init genserver" do
    employee_request1 = insert(:il, :employee_request)
    employee_request2 = insert(:il, :employee_request)
    insert(:il, :employee_request)
    inserted_at = NaiveDateTime.add(NaiveDateTime.utc_now(), -86_400 * 10, :seconds)

    employee_request1
    |> Ecto.Changeset.change(inserted_at: inserted_at)
    |> Repo.update()
    employee_request2
    |> Ecto.Changeset.change(inserted_at: inserted_at)
    |> Repo.update()

    insert(:prm, :global_parameter, parameter: "employee_request_term_unit", value: "DAYS")
    insert(:prm, :global_parameter, parameter: "employee_request_expiration", value: "5")
    assert 3 = Request |> Repo.all() |> Enum.count

    GenServer.cast(Terminator, {:terminate, 1})
    Process.sleep(1000)

    request_id = employee_request1.id
    expired_status = Request.status(:expired)
    assert %{status: ^expired_status} = Repo.get(Request, request_id)
    assert [event1, _event2] = EventManagerRepo.all(Event)
    assert %Event{
      entity_type: "EmployeeRequest",
      event_type: "StatusChangeEvent",
      entity_id: ^request_id,
      properties: %{"new_status" => ^expired_status}
    } = event1
  end
end
