defmodule EHealth.Web.ContractController do
  @moduledoc false

  use EHealth.Web, :controller

  alias EHealth.Contracts
  alias EHealth.ContractRequests
  alias Scrivener.Page

  action_fallback(EHealth.Web.FallbackController)

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    client_type = conn.assigns.client_type

    with {:ok, %Page{} = paging, references} <- Contracts.list(params, client_type, headers) do
      render(conn, "index.json", contracts: paging.entries, paging: paging, references: references)
    end
  end

  def show(conn, %{"id" => id} = params) do
    with {:ok, contract, references} <- Contracts.get_by_id(id, params) do
      conn
      |> assign(:urgent, %{
        "documents" => ContractRequests.gen_relevant_get_links(contract.contract_request_id, contract.status)
      })
      |> render("show.json", contract: contract, references: references)
    end
  end

  def update(%Plug.Conn{req_headers: headers} = conn, %{"id" => id} = params) do
    with {:ok, contract, references} <- Contracts.update(id, Map.delete(params, "id"), headers) do
      render(conn, "show.json", contract: contract, references: references)
    end
  end

  def printout_content(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    client_type = conn.assigns.client_type

    with {:ok, contract, printout_content} <- Contracts.get_printout_content(id, client_type, headers) do
      render(conn, "printout_content.json", contract: contract, printout_content: printout_content)
    end
  end
end
