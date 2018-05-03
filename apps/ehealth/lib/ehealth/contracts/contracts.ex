defmodule EHealth.Contracts do
  @moduledoc false

  alias EHealth.Validators.Preload
  alias EHealth.Utils.MapDeepMerge

  @ops_api Application.get_env(:ehealth, :api_resolvers)[:ops]

  def get_by_id(id, params) do
    with {:ok, %{"data" => contract}} <- @ops_api.get_contract(id, []),
         :ok <- validate_contractor_legal_entity_id(contract, params),
         {:ok, contract_data} <- load_contract_references(contract) do
      {:ok, contract_data}
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

  defp load_contract_references(contract) do
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

    {:ok, {contract, references}}
  end
end
