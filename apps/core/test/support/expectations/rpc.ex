defmodule Core.Expectations.RPC do
  @moduledoc false

  import Mox

  def expect_encounter_status(status, times \\ 1)

  def expect_encounter_status(nil, times) do
    expect(RPCWorkerMock, :run, times, fn _, _, :encounter_status_by_id, _, _ ->
      nil
    end)
  end

  def expect_encounter_status(status, times) do
    expect(RPCWorkerMock, :run, times, fn _, _, :encounter_status_by_id, _, _ ->
      {:ok, status}
    end)
  end

  def expect_uaddresses_validate(response \\ :ok, times \\ 1) do
    expect(RPCWorkerMock, :run, times, fn _, Uaddresses.Rpc, :validate, _, _ ->
      response
    end)
  end
end
