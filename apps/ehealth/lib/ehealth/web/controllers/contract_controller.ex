defmodule EHealth.Web.ContractController do
  @moduledoc false

  use EHealth.Web, :controller

  alias Core.ContractRequests
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.Contracts
  alias Core.Contracts.CapitationContract
  alias Core.Contracts.ReimbursementContract
  alias Scrivener.Page
  import Core.API.Helpers.Connection, only: [get_client_id: 1]

  @capitation CapitationContract.type()
  @reimbursement ReimbursementContract.type()

  action_fallback(EHealth.Web.FallbackController)

  def index(%Plug.Conn{req_headers: headers} = conn, %{"type" => _type} = params) do
    client_type = conn.assigns.client_type
    client_id = get_client_id(headers)

    with {:ok, %Page{} = paging, references} <- Contracts.list(params, client_type, client_id) do
      render(conn, "index.json", contracts: paging.entries, paging: paging, references: references)
    end
  end

  def show(conn, %{"id" => id, "type" => @capitation} = params) do
    with {:ok, contract, references} <- Contracts.get_by_id_with_client_validation(id, params),
         %CapitationContractRequest{status: status} = references[:contract_request][contract.contract_request_id],
         {:ok, documents} <- ContractRequests.gen_relevant_get_links(contract.contract_request_id, status) do
      conn
      |> assign(:urgent, %{"documents" => documents})
      |> render("show.json", contract: contract, references: references)
    end
  end

  def show(conn, %{"id" => id, "type" => @reimbursement} = params) do
    with {:ok, contract, references} <- Contracts.get_by_id_with_client_validation(id, params),
         %ReimbursementContractRequest{status: status} =
           references[:reimbursement_contract_request][contract.contract_request_id],
         {:ok, documents} <- ContractRequests.gen_relevant_get_links(contract.contract_request_id, status) do
      conn
      |> assign(:urgent, %{"documents" => documents})
      |> render("show.json", contract: contract, references: references)
    end
  end

  def show_employees(%Plug.Conn{req_headers: headers} = conn, %{"id" => id} = params) do
    with {:ok, paging, references} <- Contracts.get_employees_by_id(id, drop_type(params), headers) do
      render(conn, "show_employees.json", contract_employees: paging.entries, paging: paging, references: references)
    end
  end

  def update(%Plug.Conn{req_headers: headers} = conn, %{"id" => id} = params) do
    with {:ok, contract, references} <- Contracts.update(id, Map.delete(drop_type(params), "id"), headers) do
      render(conn, "show.json", contract: contract, references: references)
    end
  end

  def prolongate(%Plug.Conn{req_headers: headers} = conn, %{"id" => id} = params) do
    with {:ok, contract, references} <- Contracts.prolongate(id, Map.delete(drop_type(params), "id"), headers) do
      render(conn, "show.json", contract: contract, references: references)
    end
  end

  def terminate(%Plug.Conn{req_headers: headers} = conn, %{"id" => id} = params) do
    params = Map.drop(params, ~w(id contractor_legal_entity_id))

    with {:ok, contract} <- Contracts.terminate(id, params, headers),
         {:ok, contract, references} <- Contracts.load_contract_references(contract) do
      render(conn, "terminate.json", contract: contract, references: references)
    end
  end

  def printout_content(%Plug.Conn{req_headers: headers} = conn, %{"id" => id, "type" => type}) do
    client_type = conn.assigns.client_type

    with {:ok, contract} <- Contracts.fetch_by_id(id, type),
         {:ok, printout_content} <- Contracts.get_printout_content(contract, client_type, headers) do
      render(conn, "printout_content.json", contract: contract, printout_content: printout_content)
    end
  end

  # ToDo: remove it after implementation type for each function
  defp drop_type(params), do: Map.delete(params, "type")
end
