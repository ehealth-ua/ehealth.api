defmodule EHealth.Web.ContractRequestController do
  @moduledoc false

  use EHealth.Web, :controller

  alias Core.ContractRequests
  alias Core.ContractRequests.CapitationContractRequest
  alias EHealth.Web.ContractView

  action_fallback(EHealth.Web.FallbackController)

  def index(conn, params) do
    with {:ok, paging} <- ContractRequests.search(params) do
      render(conn, "index.json", contract_requests: paging.entries, paging: paging)
    end
  end

  def draft(conn, _) do
    with %{"id" => id, "statute_url" => statute_url, "additional_document_url" => additional_document_url} <-
           ContractRequests.draft() do
      render(conn, "draft.json", id: id, statute_url: statute_url, additional_document_url: additional_document_url)
    end
  end

  def create(%Plug.Conn{} = conn, params) do
    with {:ok, %CapitationContractRequest{} = contract_request, references} <-
           ContractRequests.create(conn.req_headers, params) do
      conn
      |> put_status(:created)
      |> render("show.json", contract_request: contract_request, references: references)
    end
  end

  def update(%Plug.Conn{} = conn, params) do
    with {:ok, %CapitationContractRequest{} = contract_request, references} <-
           ContractRequests.update(conn.req_headers, params) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def show(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    client_type = conn.assigns.client_type

    with {:ok, %CapitationContractRequest{} = contract_request, references} <-
           ContractRequests.get_by_id(headers, client_type, id) do
      conn
      |> assign(:urgent, %{"documents" => ContractRequests.gen_relevant_get_links(id, contract_request.status)})
      |> render("show.json", contract_request: contract_request, references: references)
    end
  end

  def update_assignee(%Plug.Conn{req_headers: headers} = conn, params) do
    update_result = ContractRequests.update_assignee(headers, params)

    with {:ok, %CapitationContractRequest{} = contract_request, references} <- update_result do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def approve(%Plug.Conn{} = conn, params) do
    with {:ok, %CapitationContractRequest{} = contract_request, references} <-
           ContractRequests.approve(conn.req_headers, params) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def approve_msp(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, %CapitationContractRequest{} = contract_request, references} <-
           ContractRequests.approve_msp(headers, params) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def terminate(%Plug.Conn{req_headers: headers} = conn, params) do
    client_type = conn.assigns.client_type

    with {:ok, %CapitationContractRequest{} = contract_request, references} <-
           ContractRequests.terminate(headers, client_type, params) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def sign_nhs(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, %CapitationContractRequest{} = contract_request, references} <-
           ContractRequests.sign_nhs(headers, params) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def sign_msp(%Plug.Conn{req_headers: headers} = conn, params) do
    client_type = conn.assigns.client_type

    with {:ok, contract, references} <- ContractRequests.sign_msp(headers, client_type, params) do
      conn
      |> put_view(ContractView)
      |> render("show.json", contract: contract, references: references)
    end
  end

  def decline(%Plug.Conn{} = conn, params) do
    with {:ok, %CapitationContractRequest{} = contract_request, references} <-
           ContractRequests.decline(conn.req_headers, params) do
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
