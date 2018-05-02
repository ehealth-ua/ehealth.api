defmodule EHealth.Web.ContractRequestController do
  @moduledoc false

  use EHealth.Web, :controller

  alias EHealth.ContractRequests
  alias EHealth.ContractRequests.ContractRequest

  action_fallback(EHealth.Web.FallbackController)

  def index(conn, params) do
    with {:ok, paging} <- ContractRequests.search(params) do
      render(conn, "index.json", contract_requests: paging.entries, paging: paging)
    end
  end

  def create(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, %ContractRequest{} = contract_request, references} <- ContractRequests.create(headers, params) do
      render(conn, "show.json", contract_request: contract_request, references: references)
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

  def terminate(%Plug.Conn{req_headers: headers} = conn, params) do
    client_type = conn.assigns.client_type

    with {:ok, %ContractRequest{} = contract_request, references} <-
           ContractRequests.terminate(headers, client_type, params) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def sign_nhs(%Plug.Conn{req_headers: headers} = conn, params) do
    client_type = conn.assigns.client_type

    with {:ok, %ContractRequest{} = contract_request} <- ContractRequests.sign_nhs(headers, client_type, params) do
      render(conn, "sign_nhs.json", contract_request: contract_request)
    end
  end
end
