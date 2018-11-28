defmodule Core.ContractRequests.RequestPack do
  @moduledoc """
  Input request structure for Contract Request
  """

  alias Core.CapitationContractRequests
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.ReimbursementContractRequests

  defstruct ~w(
    type
    schema
    provider
    input_params
    decoded_content
    contract_request
    contract_request_id
  )a

  @capitation CapitationContractRequest.type()
  @reimbursement ReimbursementContractRequest.type()

  def new(%{"type" => _} = params) do
    struct(__MODULE__, map_params(params))
  end

  def put_decoded_content(%__MODULE__{} = pack, decoded_content), do: Map.put(pack, :decoded_content, decoded_content)

  def put_contract_request(%__MODULE__{} = pack, contract_request),
    do: Map.put(pack, :contract_request, contract_request)

  defp map_params(%{"type" => type} = params) do
    %{
      type: type,
      schema: get_schema_by_type(type),
      provider: get_provider_by_type(type),
      contract_request_id: params["id"],
      input_params: Map.drop(params, ~w(id type))
    }
  end

  def get_schema_by_type(@capitation), do: CapitationContractRequest
  def get_schema_by_type(@reimbursement), do: ReimbursementContractRequest

  defp get_provider_by_type(@capitation), do: CapitationContractRequests
  defp get_provider_by_type(@reimbursement), do: ReimbursementContractRequests
end
