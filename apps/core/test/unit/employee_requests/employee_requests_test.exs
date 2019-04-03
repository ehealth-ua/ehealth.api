defmodule Core.Unit.EmployeeRequestsTest do
  @moduledoc false

  use Core.ConnCase, async: false
  import Mox

  alias Core.Repo
  alias Ecto.UUID
  alias Core.EmployeeRequests
  alias Core.EmployeeRequests.EmployeeRequest, as: Request

  @expired_status Request.status(:expired)

  setup :verify_on_exit!
  setup :set_mox_global

  test "terminate outdated employee_requests" do
    expect(KafkaMock, :publish_to_event_manager, 2, fn _ -> :ok end)

    employee_id = UUID.generate()
    inserted_at = Timex.shift(NaiveDateTime.utc_now(), days: -10)
    employee_request_expired = insert(:il, :employee_request, employee_id: employee_id, inserted_at: inserted_at)
    insert(:il, :employee_request, inserted_at: inserted_at)
    insert(:il, :employee_request)
    insert(:prm, :global_parameter, parameter: "employee_request_term_unit", value: "DAYS")
    insert(:prm, :global_parameter, parameter: "employee_request_expiration", value: "5")
    EmployeeRequests.terminate_employee_requests()
    assert %{status: @expired_status} = Repo.get(Request, employee_request_expired.id)
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
