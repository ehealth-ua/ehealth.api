defmodule EHealth.Web.ContractRequestController do
  @moduledoc false

  use EHealth.Web, :controller

  alias Core.ContractRequests
  alias Core.ContractRequests.RequestPack
  alias EHealth.Web.ContractView

  action_fallback(EHealth.Web.FallbackController)

  def index(conn, params) do
    with {:ok, %{entries: contract_requests} = paging} <- ContractRequests.search(params) do
      render(conn, "index.json", contract_requests: contract_requests, paging: paging)
    end
  end

  def draft(conn, _) do
    with %{"id" => id, "statute_url" => statute_url, "additional_document_url" => additional_document_url} <-
           ContractRequests.draft() do
      render(conn, "draft.json", id: id, statute_url: statute_url, additional_document_url: additional_document_url)
    end
  end

  def create(%Plug.Conn{} = conn, %{} = params) do
    with {:ok, contract_request, references} <- ContractRequests.create_from_draft(conn.req_headers, params) do
      conn
      |> put_status(:created)
      |> render("show.json", contract_request: contract_request, references: references)
    end
  end

  def update(%Plug.Conn{} = conn, params) do
    with {:ok, contract_request, references} <- ContractRequests.update(conn.req_headers, params) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def show(%Plug.Conn{req_headers: headers} = conn, %{"id" => id, "type" => _} = params) do
    client_type = conn.assigns.client_type
    pack = RequestPack.new(params)

    with {:ok, contract_request, references} <-
           ContractRequests.get_by_id_with_client_validation(headers, client_type, pack) do
      conn
      |> assign(:urgent, %{
        "documents" => ContractRequests.gen_relevant_get_links(id, contract_request.type, contract_request.status)
      })
      |> render("show.json", contract_request: contract_request, references: references)
    end
  end

  def update_assignee(%Plug.Conn{req_headers: headers} = conn, params) do
    update_result = ContractRequests.update_assignee(params, headers)

    with {:ok, %{__struct__: _} = contract_request, references} <- update_result do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def approve(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, %{__struct__: _} = contract_request, references} <- ContractRequests.approve(params, headers) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def approve_msp(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, %{__struct__: _} = contract_request, references} <- ContractRequests.approve_msp(headers, params) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def terminate(%Plug.Conn{req_headers: headers} = conn, params) do
    client_type = conn.assigns.client_type

    with {:ok, %{__struct__: _} = contract_request, references} <-
           ContractRequests.terminate(headers, client_type, params) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def sign_nhs(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, %{__struct__: _} = contract_request, references} <- ContractRequests.sign_nhs(headers, params) do
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

  def decline(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, contract_request, references} <- ContractRequests.decline(params, headers) do
      render(conn, "show.json", contract_request: contract_request, references: references)
    end
  end

  def get_partially_signed_content(%Plug.Conn{req_headers: headers} = conn, %{"id" => _} = params) do
    with {:ok, url} <- ContractRequests.get_partially_signed_content_url(headers, drop_type(params)) do
      render(conn, "partially_signed_content.json", url: url)
    end
  end

  def printout_content(%Plug.Conn{req_headers: headers} = conn, params) do
    client_type = conn.assigns.client_type

    with {:ok, contract_request, printout_content} <-
           ContractRequests.get_printout_content(params, client_type, headers) do
      render(conn, "printout_content.json", contract_request: contract_request, printout_content: printout_content)
    end
  end

  # ToDo: remove it after implementation type for each function
  defp drop_type(params), do: Map.delete(params, "type")
end
