defmodule EHealth.Web.ContractRequestController do
  @moduledoc false

  use EHealth.Web, :controller
  alias EHealth.ContractRequests
  alias EHealth.ContractRequests.ContractRequest
  alias EHealth.Web.ContractView

  action_fallback(EHealth.Web.FallbackController)

  def index(conn, params) do
    with {:ok, paging} <- ContractRequests.search(params) do
      render(conn, "index.json", contract_requests: paging.entries, paging: paging)
    end
  end

  def create(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, %ContractRequest{} = contract_request, references} <- ContractRequests.create(headers, params) do
      conn
      |> put_status(:created)
      |> render("show.json", contract_request: contract_request, references: references)
    end
  end

  def update(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, %ContractRequest{} = contract_request, references} <- ContractRequests.update(headers, params) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def show(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    client_type = conn.assigns.client_type

    with {:ok, %ContractRequest{} = contract_request, references} <-
           ContractRequests.get_by_id(headers, client_type, id) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def approve(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, %ContractRequest{} = contract_request, references} <- ContractRequests.approve(headers, params) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def approve_msp(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, %ContractRequest{} = contract_request, references} <- ContractRequests.approve_msp(headers, params) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def terminate(%Plug.Conn{req_headers: headers} = conn, params) do
    client_type = conn.assigns.client_type

    with {:ok, %ContractRequest{} = contract_request, references} <-
           ContractRequests.terminate(headers, client_type, params) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def sign_nhs(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, %ContractRequest{} = contract_request, references} <- ContractRequests.sign_nhs(headers, params) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def sign_msp(%Plug.Conn{req_headers: headers} = conn, params) do
    client_type = conn.assigns.client_type

    with {:ok, contract, references} <- ContractRequests.sign_msp(headers, client_type, params) do
      render(conn, ContractView, "show.json", contract: contract, references: references)
    end
  end

  def decline(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, %ContractRequest{} = contract_request, references} <- ContractRequests.decline(headers, params) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def get_partially_signed_content(%Plug.Conn{req_headers: headers} = conn, %{"id" => _} = params) do
    with {:ok, url} <- ContractRequests.get_partially_signed_content_url(headers, params) do
      render(conn, "partially_signed_content.json", url: url)
    end
  end

  def printout_content(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    client_type = conn.assigns.client_type

    with {:ok, contract_request, printout_content} <- ContractRequests.get_printout_content(id, client_type, headers) do
      render(conn, "printout_content.json", contract_request: contract_request, printout_content: printout_content)
    end
  end
end
