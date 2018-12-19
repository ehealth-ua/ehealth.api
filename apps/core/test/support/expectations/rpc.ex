defmodule Core.Expectations.RPC do
  @moduledoc false

  import Mox

  def expect_encounter_status(status, times \\ 1)

  def expect_encounter_status(nil, times) do
    expect(RPCWorkerMock, :run, times, fn _, _, :encounter_status_by_id, _ ->
      nil
    end)
  end

  def expect_encounter_status(status, times) do
    expect(RPCWorkerMock, :run, times, fn _, _, :encounter_status_by_id, _ ->
      {:ok, status}
    end)
  end

  def expect_uaddresses_validate(response \\ :ok, times \\ 1) do
    expect(RPCWorkerMock, :run, times, fn _, Uaddresses.Rpc, :validate, _ ->
      response
    end)
  end

  def expect_ops_last_medication_request_dates(params, times_called \\ 1)

  def expect_ops_last_medication_request_dates(nil, times_called) do
    expect(RPCWorkerMock, :run, times_called, fn _, _, :last_medication_request_dates, _ ->
      {:ok, nil}
    end)
  end

  def expect_ops_last_medication_request_dates(:error, times_called) do
    expect(RPCWorkerMock, :run, times_called, fn _, _, :last_medication_request_dates, _ ->
      {:error, "error message"}
    end)
  end

  def expect_ops_last_medication_request_dates(params, times_called) when is_map(params) do
    expect(RPCWorkerMock, :run, times_called, fn _, _, :last_medication_request_dates, _ ->
      {:ok, Map.merge(%{"started_at" => Date.utc_today(), "ended_at" => Date.utc_today()}, params)}
    end)
  end
end
