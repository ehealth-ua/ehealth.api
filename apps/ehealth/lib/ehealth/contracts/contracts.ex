defmodule EHealth.Contracts do
  @moduledoc false

  import EHealth.Utils.Connection, only: [get_client_id: 1]

  alias EHealth.Validators.Preload
  alias EHealth.Utils.MapDeepMerge
  alias EHealth.Contracts.Search
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.PRMRepo
  alias Scrivener.Page

  @ops_api Application.get_env(:ehealth, :api_resolvers)[:ops]

  def get_by_id(id, params) do
    with {:ok, %{"data" => contract}} <- @ops_api.get_contract(id, []),
         :ok <- validate_contractor_legal_entity_id(contract, params),
         {:ok, contract, references} <- load_contract_references(contract) do
      {:ok, contract, references}
    else
      error -> error
    end
  end

  defp validate_contractor_legal_entity_id(contract, %{"contractor_legal_entity_id" => contractor_legal_entity_id}) do
    if contract["contractor_legal_entity_id"] == contractor_legal_entity_id,
      do: :ok,
      else: {:error, {:forbidden, "You are not allowed to view this contract"}}
  end

  defp validate_contractor_legal_entity_id(_contract, _params), do: :ok

  def load_contract_references(contract) do
    contract_references =
      Preload.preload_references(contract, [
        {"contractor_legal_entity_id", :legal_entity},
        {"contractor_owner_id", :employee},
        {"nhs_legal_entity_id", :legal_entity},
        {"nhs_signer_id", :employee},
        {"contract_request_id", :contract_request}
      ])

    contract_request = get_in(contract_references, [:contract_request, contract["contract_request_id"]])

    contract_request_references =
      Preload.preload_references(contract_request, [
        {[:contractor_employee_divisions, "$", "employee_id"], :employee},
        {[:contractor_employee_divisions, "$", "division_id"], :division}
      ])

    references = MapDeepMerge.merge(contract_references, contract_request_references)

    {:ok, contract, references}
  end

  def search(headers, client_type, search_params) do
    client_id = get_client_id(headers)

    with %Ecto.Changeset{valid?: true, changes: changes} <- Search.changeset(search_params),
         {:edrpou, {:ok, changes}} <- {:edrpou, validate_edrpou(changes)},
         {:ok, changes} <- validate_client_type(client_id, client_type, changes),
         {:ok, contracts} <- @ops_api.get_contracts(changes, headers),
         {:ok, references} <- load_contracts_references(contracts["data"]) do
      {:ok, contracts, references}
    else
      {:edrpou, _} ->
        get_empty_response(search_params)

      error ->
        error
    end
  end

  defp validate_edrpou(search_params) do
    edrpou = Map.get(search_params, :edrpou)
    contractor_legal_entity_id = Map.get(search_params, :contractor_legal_entity_id)
    search_params = Map.delete(search_params, :edrpou)

    with false <- is_nil(edrpou),
         %LegalEntity{} = legal_entity <- PRMRepo.get_by(LegalEntity, edrpou: edrpou) do
      cond do
        contractor_legal_entity_id == legal_entity.id ->
          {:ok, search_params}

        is_nil(contractor_legal_entity_id) ->
          search_params = Map.put(search_params, :contractor_legal_entity_id, legal_entity.id)
          {:ok, search_params}

        true ->
          :error
      end
    else
      true -> {:ok, search_params}
      nil -> :error
    end
  end

  defp validate_client_type(_, "NHS", search_params), do: {:ok, search_params}

  defp validate_client_type(client_id, "MSP", %{contractor_legal_entity_id: id} = search_params) do
    cond do
      id == client_id -> {:ok, search_params}
      is_nil(id) -> {:ok, Map.put(search_params, :contractor_legal_entity_id, client_id)}
      true -> get_empty_response(search_params)
    end
  end

  defp load_contracts_references(contracts) do
    references =
      Preload.preload_references_for_list(contracts, [
        {"contractor_owner_id", :employee}
      ])

    {:ok, references}
  end

  defp get_empty_response(params) do
    {:ok,
     %{
       "data" => [],
       "paging" => %Page{
         entries: [],
         page_number: 1,
         page_size: Map.get(params, "page_size", 50),
         total_entries: 0,
         total_pages: 1
       }
     }, %{}}
  end
end
