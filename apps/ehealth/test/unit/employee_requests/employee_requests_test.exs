defmodule EHealth.Unit.EmployeeRequestsTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  alias EHealth.EmployeeRequests
  alias EHealth.EmployeeRequests.EmployeeRequest, as: Request
  alias EHealth.EventManagerRepo
  alias EHealth.EventManager.Event
  alias EHealth.Repo
  alias Ecto.UUID

  @expired_status Request.status(:expired)

  test "terminate outdated employee_requests" do
    employee_id = UUID.generate()
    inserted_at = Timex.shift(NaiveDateTime.utc_now(), days: -10)

    employee_request_expired = insert(:il, :employee_request, employee_id: employee_id, inserted_at: inserted_at)
    _employee_request_expired2 = insert(:il, :employee_request, inserted_at: inserted_at)
    employee_request_active = insert(:il, :employee_request)

    insert(:prm, :global_parameter, parameter: "employee_request_term_unit", value: "DAYS")
    insert(:prm, :global_parameter, parameter: "employee_request_expiration", value: "5")

    EmployeeRequests.terminate_employee_requests()

    assert %{status: @expired_status} = Repo.get(Request, employee_request_expired.id)

    [event1 | _] = events = EventManagerRepo.all(Event)
    events_expired_entities_ids = Enum.map(events, &Map.get(&1, :entity_id))
    events_expired_properties = Enum.map(events, &Map.get(&1, :properties))

    assert 2 = Enum.count(events)
    assert %Event{} = event1
    assert "EmployeeRequest" == event1.entity_type
    assert "StatusChangeEvent" == event1.event_type
    assert employee_request_expired.id in events_expired_entities_ids
    refute employee_request_active.id in events_expired_entities_ids

    assert %{
             "status" => %{"new_value" => @expired_status},
             "employee_id" => %{"new_value" => employee_id}
           } in events_expired_properties
  end
end
