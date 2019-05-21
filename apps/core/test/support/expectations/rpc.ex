defmodule Core.Expectations.RPC do
  @moduledoc false

  import Mox

  def expect_delete_user_role(response, times \\ 1) do
    expect(RPCWorkerMock, :run, times, fn _, _, :delete_user_role, _ ->
      response
    end)
  end

  def expect_settlement_by_id(response, times \\ 1) do
    expect(RPCWorkerMock, :run, times, fn _, _, :settlement_by_id, _ ->
      response
    end)
  end

  def expect_search_legal_entity(response, times \\ 1) do
    expect(RPCEdrWorkerMock, :run, times, fn _, _, :search_legal_entity, _ ->
      response
    end)
  end

  def expect_get_legal_entity_detailed_info(response, times \\ 1) do
    expect(RPCEdrWorkerMock, :run, times, fn _, _, :get_legal_entity_detailed_info, _ ->
      response
    end)
  end

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
    expect(RPCWorkerMock, :run, times, fn _, Uaddresses.Rpc, :validate, _ -> response end)
  end

  def expect_ops_last_medication_request_dates(params, times_called \\ 1)

  def expect_ops_last_medication_request_dates(nil, times_called) do
    expect(RPCWorkerMock, :run, times_called, fn "ops", OPS.Rpc, :last_medication_request_dates, _ ->
      {:ok, nil}
    end)
  end

  def expect_ops_last_medication_request_dates(:error, times_called) do
    expect(RPCWorkerMock, :run, times_called, fn "ops", OPS.Rpc, :last_medication_request_dates, _ ->
      {:error, "error message"}
    end)
  end

  def expect_ops_last_medication_request_dates(params, times_called) when is_map(params) do
    expect(RPCWorkerMock, :run, times_called, fn "ops", OPS.Rpc, :last_medication_request_dates, _ ->
      {:ok, Map.merge(%{"started_at" => Date.utc_today(), "ended_at" => Date.utc_today()}, params)}
    end)
  end

  def expect_persons_search_result(data, times \\ 1)

  def expect_persons_search_result(records, times) when is_list(records) do
    expect(RPCWorkerMock, :run, times, fn _, _, :search_persons, _ ->
      {:ok,
       Enum.map(records, fn record ->
         Map.merge(record, %{id: record[:id] || Ecto.UUID.generate()})
       end)}
    end)
  end

  def expect_persons_search_result(params, times) do
    expect(RPCWorkerMock, :run, times, fn _, _, :search_persons, [search_params] ->
      {:ok,
       [
         search_params
         |> convert_string_keys_to_atoms
         |> Map.merge(params)
         |> Map.merge(%{id: params[:id] || Ecto.UUID.generate()})
       ]}
    end)
  end

  defp convert_string_keys_to_atoms(record) when is_map(record) do
    Enum.reduce(record, Map.new(), fn {key, value}, acc ->
      Map.put(acc, String.to_atom(key), convert_string_keys_to_atoms(value))
    end)
  end

  defp convert_string_keys_to_atoms(value), do: value
end
