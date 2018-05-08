defmodule EHealth.LegalEntities.ContractSuspender do
  @moduledoc false

  alias EHealth.Utils.Log

  @ops_api Application.get_env(:ehealth, :api_resolvers)[:ops]
  @status_verified "VERIFIED"

  def status_verified, do: @status_verified

  def maybe_suspend_contracts?(%{changes: changes}, :party) do
    maybe_suspend_contracts?(changes, ~w(first_name last_name second_name)a)
  end

  def maybe_suspend_contracts?(%{changes: changes}, :employee) do
    maybe_suspend_contracts?(changes, ~w(employee_type status)a)
  end

  def maybe_suspend_contracts?(%{changes: changes}, :legal_entity) do
    maybe_suspend_contracts?(changes, ~w(name addresses status)a)
  end

  def maybe_suspend_contracts?(changes, keys) when is_list(keys) do
    Enum.any?(keys, &Map.has_key?(changes, &1))
  end

  def ops_get_contracts(params, headers) do
    case @ops_api.get_contracts(params, headers) do
      # no contracts for legal_entity. Mark transaction as completed
      {:ok, %{"data" => []}} ->
        {:ok, "no contracts for suspend"}

      # contracts found
      {:ok, %{"data" => contracts}} when is_list(contracts) ->
        {:ok, contracts}

      # invalid response format. Break transaction
      {:ok, _} ->
        {:error, {"Invalid response format returned from OPS.get_contracts", params}}

      # request failed. Break transaction
      {:error, reason} ->
        {:error, {"Failed get response from OPS.get_contracts with #{reason}", params}}
    end
  end

  def ops_suspend_contracts(%{ops_get_contracts: contracts}, headers) when length(contracts) > 0 do
    ids = fetch_contract_ids(contracts)

    with {:ok, resp} <- @ops_api.suspend_contracts(ids, headers),
         {:ok, suspended_amount} <- check_suspend_contracts_response(resp),
         :ok <- check_suspended_contracts_amount(ids, suspended_amount, headers) do
      {:ok, {ids, headers}}
    else
      {:error, reason} -> {:error, {reason, ids}}
    end
  end

  def ops_suspend_contracts(_contracts, _headers), do: {:ok, "no contracts for suspend"}

  defp fetch_contract_ids(data), do: Enum.map(data, &Map.get(&1, "id"))

  defp check_suspend_contracts_response(%{"data" => %{"suspended" => amount}}), do: {:ok, amount}

  defp check_suspend_contracts_response(resp),
    do: {:error, "Response from OPS suspend contracts not matched pattern. Response: #{inspect(resp)}"}

  defp check_suspended_contracts_amount(ids, contracts_amount, _) when length(ids) == contracts_amount, do: :ok

  defp check_suspended_contracts_amount(ids, contracts_amount, headers) do
    {:ok, _} = @ops_api.renew_contracts(ids, headers)
    {:error, "Expected suspended contracts amount are #{length(ids)}. Given #{contracts_amount}"}
  end

  def maybe_rollback({:ok, %{update_legal_entity: legal_entity}}), do: {:ok, legal_entity}
  def maybe_rollback({:ok, %{update_employee: employee}}), do: {:ok, employee}

  def maybe_rollback({:error, :ops_get_contracts, {reason, params}, _changes_so_far}) do
    Log.error("Cannot get contracts from OPS with params #{inspect(params)}. Reason: #{reason}")

    {:error, {:service_unavailable, "Cannot suspend contracts. Try later"}}
  end

  def maybe_rollback({:error, :ops_suspend_contracts, {reason, ids}, _changes_so_far}) do
    Log.error("Cannot suspend contracts on OPS with ids #{inspect(ids)}. Reason: #{reason}")

    {:error, {:service_unavailable, "Cannot suspend contracts. Try later"}}
  end

  def maybe_rollback({:error, _reason, error, changes_so_far}) do
    {ids, headers} = changes_so_far.ops_suspend_contracts
    {:ok, _} = @ops_api.renew_contracts(ids, headers)
    {:error, error}
  end
end
