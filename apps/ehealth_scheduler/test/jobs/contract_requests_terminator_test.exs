defmodule EHealthScheduler.Jobs.ContractRequestsTerminatorTest do
  @moduledoc false

  use Core.ConnCase
  import Ecto.Query
  alias Core.EventManager.Event
  alias Core.EventManagerRepo
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.Repo
  alias EHealthScheduler.Jobs.ContractRequestsTerminator

  test "run/0" do
    start_date = ~D[2017-01-01]

    insert(:il, :capitation_contract_request, start_date: ~D[3000-01-01], status: CapitationContractRequest.status(:new))

    insert(:il, :capitation_contract_request, start_date: start_date, status: CapitationContractRequest.status(:new))
    insert(:il, :capitation_contract_request, start_date: start_date, status: CapitationContractRequest.status(:new))

    insert(:il, :capitation_contract_request,
      start_date: start_date,
      status: CapitationContractRequest.status(:in_process)
    )

    insert(:il, :capitation_contract_request,
      start_date: start_date,
      status: CapitationContractRequest.status(:approved)
    )

    insert(:il, :capitation_contract_request,
      start_date: start_date,
      status: CapitationContractRequest.status(:nhs_signed)
    )

    insert(:il, :capitation_contract_request,
      start_date: start_date,
      status: CapitationContractRequest.status(:pending_nhs_sign)
    )

    insert(:il, :capitation_contract_request,
      start_date: start_date,
      status: CapitationContractRequest.status(:declined)
    )

    insert(:il, :capitation_contract_request,
      start_date: start_date,
      status: CapitationContractRequest.status(:terminated)
    )

    assert 3 == count_by_status(CapitationContractRequest.status(:new))
    assert 1 == count_by_status(CapitationContractRequest.status(:in_process))
    assert 1 == count_by_status(CapitationContractRequest.status(:approved))
    assert 1 == count_by_status(CapitationContractRequest.status(:nhs_signed))
    assert 1 == count_by_status(CapitationContractRequest.status(:pending_nhs_sign))
    assert 1 == count_by_status(CapitationContractRequest.status(:declined))
    assert 1 == count_by_status(CapitationContractRequest.status(:terminated))

    ContractRequestsTerminator.run()

    assert 1 == count_by_status(CapitationContractRequest.status(:new))
    assert 1 == count_by_status(CapitationContractRequest.status(:declined))
    assert 7 == count_by_status(CapitationContractRequest.status(:terminated))

    assert events = EventManagerRepo.all(Event)

    assert 6 == Enum.count(events)

    terminated_status = CapitationContractRequest.status(:terminated)

    for event <- events do
      assert %Event{
               entity_type: "CapitationContractRequest",
               event_type: "StatusChangeEvent",
               properties: %{"status" => %{"new_value" => ^terminated_status}}
             } = event
    end
  end

  defp count_by_status(status) do
    CapitationContractRequest
    |> where([cr], cr.status == ^status)
    |> select([cr], count(cr.id))
    |> Repo.one()
  end
end
