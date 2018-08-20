defmodule Core.Unit.EmployeeRequestsTest do
  @moduledoc false

  use Core.ConnCase, async: false

  alias Core.Repo
  alias Core.EventManagerRepo
  alias Ecto.UUID
  alias Core.EmployeeRequests
  alias Core.EmployeeRequests.EmployeeRequest, as: Request
  alias Core.EventManager.Event

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

  test "rollback suspended contracts on employee_request approve when employee.division_id invalid" do
    %{id: legal_entity_id} = insert(:prm, :legal_entity)

    data =
      employee_request_data()
      |> put_in([:party, :email], "mis_bot_1493831618@user.com")
      |> put_in([:division_id], UUID.generate())
      |> put_in([:legal_entity_id], legal_entity_id)

    %{id: request_id} = insert(:il, :employee_request, employee_id: nil, data: data)

    assert {:error, %Ecto.Changeset{valid?: false}} = EmployeeRequests.approve(request_id, [])
  end
end
