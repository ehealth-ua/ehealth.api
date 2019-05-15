defmodule Core.Contracts.ContractSuspender do
  @moduledoc false

  import Ecto.Query

  alias Core.Contracts.CapitationContract
  alias Core.PRMRepo

  @contract_status_verified CapitationContract.status(:verified)

  def suspend_contracts?(%{changes: changes}, :party) do
    suspend_contracts?(changes, ~w(first_name last_name second_name)a)
  end

  def suspend_contracts?(%{changes: changes}, :employee) do
    suspend_contracts?(changes, ~w(employee_type status)a)
  end

  def suspend_contracts?(%{changes: changes}, :legal_entity) do
    suspend_contracts?(changes, ~w(name addresses status)a)
  end

  def suspend_contracts?(changes, keys) when is_list(keys) do
    Enum.any?(keys, &Map.has_key?(changes, &1))
  end

  def suspend_by_contractor_owner_ids([]), do: :ok

  def suspend_by_contractor_owner_ids(owner_ids) when is_list(owner_ids) do
    query_suspendable_contracts()
    |> where([c], c.contractor_owner_id in ^owner_ids)
    |> PRMRepo.update_all(set: [is_suspended: true])
    |> case do
      {_updated_count, nil} -> :ok
      err -> err
    end
  end

  def suspend_by_contractor_legal_entity_id(contractor_legal_entity_id) do
    query_suspendable_contracts()
    |> where([c], c.contractor_legal_entity_id == ^contractor_legal_entity_id)
    |> PRMRepo.update_all(set: [is_suspended: true])
    |> case do
      {_updated_count, nil} -> :ok
      err -> err
    end
  end

  def suspend_contracts(contracts) do
    ids = Enum.map(contracts, &Map.get(&1, :id))

    with {:ok, suspended} <- update_is_suspended(ids, true),
         :ok <- check_suspended_contracts_amount(ids, suspended) do
      {:ok, ids}
    else
      {:error, reason} -> {:error, {reason, ids}}
    end
  end

  defp query_suspendable_contracts do
    CapitationContract
    |> where([c], c.status == @contract_status_verified)
    |> where([c], c.is_suspended == false)
  end

  defp check_suspended_contracts_amount(ids, contracts_amount) when length(ids) == contracts_amount, do: :ok

  defp check_suspended_contracts_amount(ids, contracts_amount) do
    {:ok, _} = update_is_suspended(ids, false)
    {:error, "Expected suspended contracts amount are #{length(ids)}. Given #{contracts_amount}"}
  end

  defp update_is_suspended(ids, is_suspended) when is_list(ids) and is_boolean(is_suspended) do
    query = where(CapitationContract, [c], c.id in ^ids)

    case PRMRepo.update_all(query, set: [is_suspended: is_suspended]) do
      {suspended, _} -> {:ok, suspended}
      err -> err
    end
  end
end
