defmodule EHealthScheduler.Contracts.TerminatorTest do
  @moduledoc false

  use Core.ConnCase, async: false
  alias Core.Contracts.CapitationContract
  alias Core.PRMRepo
  import EHealthScheduler.Contracts.Terminator

  test "terminate outdated declaration_requests" do
    tomorrow = Date.add(Date.utc_today(), 1)
    yesterday = Date.add(Date.utc_today(), -1)

    contract = insert(:prm, :capitation_contract, end_date: tomorrow)

    terminated_ids =
      Enum.reduce(1..9, [], fn _, acc ->
        %{id: id} = insert(:prm, :capitation_contract, end_date: yesterday)
        [id | acc]
      end)

    terminate_contracts()
    assert_receive :terminated_contracts

    assert 9 =
             terminated_ids
             |> Enum.reduce([], fn id, acc ->
               contract = PRMRepo.get(CapitationContract, id)
               assert contract.status == CapitationContract.status(:terminated)
               [id | acc]
             end)
             |> Enum.count()

    contract = PRMRepo.get(CapitationContract, contract.id)
    refute contract.status == CapitationContract.status(:terminated)
  end
end
