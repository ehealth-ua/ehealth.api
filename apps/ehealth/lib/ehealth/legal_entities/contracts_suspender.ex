defmodule EHealth.LegalEntities.ContractSuspender do
  @moduledoc false

  alias EHealth.Utils.Log
  alias EHealth.Contracts
  alias Scrivener.Page

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

  # when length(contracts) > 0 do

  def ops_suspend_contracts(contracts) do
    ids = fetch_contract_ids(contracts)

    with {:ok, suspended} <- Contracts.update_is_suspended(ids, true),
         :ok <- check_suspended_contracts_amount(ids, suspended) do
      {:ok, ids}
    else
      {:error, reason} -> {:error, {reason, ids}}
    end
  end

  def ops_suspend_contracts(_contracts), do: {:ok, "no contracts for suspend"}

  defp fetch_contract_ids(data), do: Enum.map(data, &Map.get(&1, "id"))

  defp check_suspended_contracts_amount(ids, contracts_amount) when length(ids) == contracts_amount, do: :ok

  defp check_suspended_contracts_amount(ids, contracts_amount) do
    {:ok, _} = Contracts.update_is_suspended(ids, false)
    {:error, "Expected suspended contracts amount are #{length(ids)}. Given #{contracts_amount}"}
  end
end
