defmodule EHealth.Contracts.TerminatorTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false
  alias Core.Contracts.Contract
  alias Core.PRMRepo
  import EHealth.Contracts.Terminator

  test "terminate outdated declaration_requests" do
    tomorrow = Date.add(Date.utc_today(), 1)
    yesterday = Date.add(Date.utc_today(), -1)

    contract = insert(:prm, :contract, end_date: tomorrow)

    terminated_ids =
      Enum.reduce(1..9, [], fn _, acc ->
        %{id: id} = insert(:prm, :contract, end_date: yesterday)
        [id | acc]
      end)

    terminate_contracts()
    assert_receive :terminated_contracts

    assert 9 =
             terminated_ids
             |> Enum.reduce([], fn id, acc ->
               contract = PRMRepo.get(Contract, id)
               assert contract.status == Contract.status(:terminated)
               [id | acc]
             end)
             |> Enum.count()

    contract = PRMRepo.get(Contract, contract.id)
    refute contract.status == Contract.status(:terminated)
  end
end
