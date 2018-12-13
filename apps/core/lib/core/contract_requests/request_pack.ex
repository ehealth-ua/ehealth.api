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
    request_params
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
      request_params: Map.drop(params, ~w(id type))
    }
  end

  def get_schema_by_type(@capitation), do: CapitationContractRequest
  def get_schema_by_type(@reimbursement), do: ReimbursementContractRequest

  def get_provider_by_type(@capitation), do: CapitationContractRequests
  def get_provider_by_type(@reimbursement), do: ReimbursementContractRequests

  def get_type_by_atom(:capitation_contract), do: @capitation
  def get_type_by_atom(:capitation_contract_request), do: @capitation
  def get_type_by_atom(:reimbursement_contract), do: @reimbursement
  def get_type_by_atom(:reimbursement_contract_request), do: @reimbursement
end
