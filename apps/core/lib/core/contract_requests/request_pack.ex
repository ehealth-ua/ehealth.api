defmodule Core.ContractRequests.RequestPack do
  @moduledoc """
  Input request structure for Contract Request
  """

  alias Core.CapitationContractRequests
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.ReimbursementContractRequests

  defstruct ~w(
    action
    type
    schema
    provider
    input_params
    decoded_content
    contract_request
    contract_request_id
  )a

  @enforce_keys ~w(action type schema provider input_params)a

  @capitation CapitationContractRequest.type()
  @reimbursement ReimbursementContractRequest.type()

  @allowed_types [@capitation, @reimbursement]
  @allowed_actions ~w(create sign_nhs sign_msp)a

  def new(action, %{"type" => type} = params) when action in @allowed_actions do
    __MODULE__
    |> struct(map_params(params, action))
    |> validate()
  end

  def put_decoded_content(%__MODULE__{} = pack, decoded_content), do: Map.put(pack, :decoded_content, decoded_content)

  def put_contract_request(%__MODULE__{} = pack, contract_request),
    do: Map.put(pack, :contract_request, contract_request)

  defp map_params(%{"type" => type} = params, action) do
    %{
      type: type,
      action: action,
      schema: get_schema_by_type(type),
      provider: get_provider_by_type(type),
      contract_request_id: params["id"],
      input_params: Map.drop(params, ~w(id type))
    }
  end

  defp get_schema_by_type(@capitation), do: CapitationContractRequest
  defp get_schema_by_type(@reimbursement), do: ReimbursementContractRequest

  defp get_provider_by_type(@capitation), do: CapitationContractRequests
  defp get_provider_by_type(@reimbursement), do: ReimbursementContractRequests

  def validate(%__MODULE__{} = pack) do
    with :ok <- validate_type(pack.type) do
      pack
    end
  end

  defp validate_type(type) when type in @allowed_types, do: :ok
  defp validate_type(type), do: {:error, {:conflict, "Contract type \"#{type}\" is not allowed"}}
end
