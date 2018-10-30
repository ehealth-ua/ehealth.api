defmodule GraphQLWeb.Resolvers.ContractRequest do
  @moduledoc false

  import Ecto.Query, only: [where: 2]
  import GraphQLWeb.Resolvers.Helpers.Search, only: [search: 2]
  import GraphQLWeb.Resolvers.Helpers.Errors, only: [format_conflict_error: 1, format_forbidden_error: 1]

  alias Absinthe.Relay.Connection
  alias Core.ContractRequests
  alias Core.ContractRequests.ContractRequest
  alias Core.Man.Templates.ContractRequestPrintoutForm
  alias Core.Repo

  def list_contract_requests(args, %{context: %{client_type: "NHS"}}) do
    ContractRequest
    |> search(args)
    |> Connection.from_query(&Repo.all/1, args)
  end

  def list_contract_requests(args, %{context: %{client_type: "MSP", client_id: client_id}}) do
    ContractRequest
    |> where(contractor_legal_entity_id: ^client_id)
    |> search(args)
    |> Connection.from_query(&Repo.all/1, args)
  end

  def get_printout_content(%ContractRequest{} = contract_request, _args, %{context: context}) do
    contract_request = Map.put(contract_request, :nhs_signed_date, Date.utc_today())

    with :ok <- ContractRequests.validate_status(contract_request, ContractRequest.status(:pending_nhs_sign)),
         :ok <-
           ContractRequests.validate_legal_entity_id(contract_request.contractor_legal_entity_id, context.client_id),
         # todo: causes N+1 problem with DB query and man templace rendening
         {:ok, printout_content} <- ContractRequestPrintoutForm.render(contract_request, context.headers) do
      {:ok, printout_content}
    else
      {:error, {:conflict, error}} -> {:error, format_conflict_error(error)}
      {:error, {:forbidden, error}} -> {:error, format_forbidden_error(error)}
      error -> error
    end
  end
end
