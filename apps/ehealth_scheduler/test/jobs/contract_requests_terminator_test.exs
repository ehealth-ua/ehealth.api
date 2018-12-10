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

    for _ <- 1..10,
        do:
          insert(:il, :capitation_contract_request,
            start_date: ~D[3000-01-01],
            status: CapitationContractRequest.status(:new)
          )

    for _ <- 1..150,
        do:
          insert(:il, :capitation_contract_request,
            start_date: start_date,
            status: CapitationContractRequest.status(:new)
          )

    for _ <- 1..100,
        do:
          insert(:il, :capitation_contract_request,
            start_date: start_date,
            status: CapitationContractRequest.status(:in_process)
          )

    for _ <- 1..50,
        do:
          insert(:il, :capitation_contract_request,
            start_date: start_date,
            status: CapitationContractRequest.status(:approved)
          )

    for _ <- 1..20,
        do:
          insert(:il, :capitation_contract_request,
            start_date: start_date,
            status: CapitationContractRequest.status(:nhs_signed)
          )

    for _ <- 1..20,
        do:
          insert(:il, :capitation_contract_request,
            start_date: start_date,
            status: CapitationContractRequest.status(:pending_nhs_sign)
          )

    for _ <- 1..15,
        do:
          insert(:il, :capitation_contract_request,
            start_date: start_date,
            status: CapitationContractRequest.status(:declined)
          )

    for _ <- 1..10,
        do:
          insert(:il, :capitation_contract_request,
            start_date: start_date,
            status: CapitationContractRequest.status(:terminated)
          )

    assert 160 == count_by_status(CapitationContractRequest.status(:new))
    assert 100 == count_by_status(CapitationContractRequest.status(:in_process))
    assert 50 == count_by_status(CapitationContractRequest.status(:approved))
    assert 20 == count_by_status(CapitationContractRequest.status(:nhs_signed))
    assert 20 == count_by_status(CapitationContractRequest.status(:pending_nhs_sign))
    assert 15 == count_by_status(CapitationContractRequest.status(:declined))
    assert 10 == count_by_status(CapitationContractRequest.status(:terminated))

    ContractRequestsTerminator.run()

    assert 10 == count_by_status(CapitationContractRequest.status(:new))
    assert 0 == count_by_status(CapitationContractRequest.status(:in_process))
    assert 0 == count_by_status(CapitationContractRequest.status(:approved))
    assert 0 == count_by_status(CapitationContractRequest.status(:nhs_signed))
    assert 0 == count_by_status(CapitationContractRequest.status(:pending_nhs_sign))
    assert 15 == count_by_status(CapitationContractRequest.status(:declined))
    assert 350 == count_by_status(CapitationContractRequest.status(:terminated))

    assert events = EventManagerRepo.all(Event)

    assert 340 == Enum.count(events)

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
