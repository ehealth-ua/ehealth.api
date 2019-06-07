defmodule EHealth.Web.DeclarationRequestController do
  @moduledoc false

  use EHealth.Web, :controller
  alias Core.DeclarationRequests
  alias Core.DeclarationRequests.DeclarationRequest
  alias Core.DeclarationRequests.Urgent
  alias Scrivener.Page
  require Logger

  @ops_api Application.get_env(:core, :api_resolvers)[:ops]

  action_fallback(EHealth.Web.FallbackController)

  def index(conn, params) do
    declaration_requests = DeclarationRequests.list(params)

    with %Page{} = paging <- declaration_requests do
      render(conn, "index.json", declaration_requests: paging.entries, paging: paging)
    end
  end

  def show(%Plug.Conn{req_headers: headers} = conn, %{"declaration_request_id" => id} = params) do
    with %DeclarationRequest{} = declaration_request <- DeclarationRequests.get_by_id!(id, params) do
      urgent_data =
        declaration_request
        |> Map.take(~w(documents)a)
        |> Map.put(
          :authentication_method_current,
          Urgent.filter_authentication_method(declaration_request.authentication_method_current)
        )

      {:ok, %{"data" => %{"hash" => hash}}} = @ops_api.get_latest_block(headers)

      conn
      |> assign(:urgent, urgent_data)
      |> render("declaration_request.json", declaration_request: declaration_request, hash: hash)
    end
  end

  def create(%Plug.Conn{req_headers: headers} = conn, %{"declaration_request" => params}) do
    with {:ok, %{urgent_data: urgent_data, finalize: result}} <- DeclarationRequests.create_offline(params, headers),
         {:ok, %{"data" => %{"hash" => hash}}} = @ops_api.get_latest_block(headers) do
      conn
      |> assign(:urgent, urgent_data)
      |> render("declaration_request.json", declaration_request: result, hash: hash)
    end
  end

  def approve(conn, %{"id" => id} = params) do
    with {:ok, %{declaration_request: declaration_request}} <-
           DeclarationRequests.approve(id, params["verification_code"], conn.req_headers) do
      render(conn, "declaration_request.json", declaration_request: declaration_request)
    else
      {:error, _, {:not_found, _}, _} ->
        Logger.error("Phone was not found for declaration request #{id}")
        {:error, %{"type" => "internal_error"}}

      {:error, :verification, {:documents_not_uploaded, reason}, _} ->
        {:conflict, "Documents #{Enum.join(reason, ", ")} is not uploaded"}

      {:error, :verification, {:ael_bad_response, _}, _} ->
        {:error, %{"type" => "internal_error"}}

      {:error, :verification, {:conflict, message}, _} ->
        {:error, {:conflict, message}}

      # handle old behaviour
      {:error, :verification, {:forbidden, message}, _} ->
        conn
        |> put_status(422)
        |> json(%{"type" => "forbidden", "message" => message})

      {:error, :verification, {:"422", message}, _} ->
        {:error, {:"422", message}}

      {:error, _, %{"meta" => _} = error, _} ->
        {:error, error}

      {:error, error} ->
        {:error, error}
    end
  end

  def sign(conn, params) do
    with {:ok, declaration} <- DeclarationRequests.sign(params, conn.req_headers) do
      render(conn, "declaration.json", declaration: declaration)
    else
      error ->
        Logger.warn("Failed to sign Declaration Request \"#{params["id"]}\". Reason: #{inspect(error)}")
        error
    end
  end

  def resend_otp(conn, %{"id" => id}) do
    with {:ok, otp} <- DeclarationRequests.resend_otp(id) do
      render(conn, "otp.json", otp: otp)
    end
  end

  def reject(conn, %{"id" => id}) do
    user_id = get_consumer_id(conn.req_headers)

    with {:ok, declaration_request} <- DeclarationRequests.reject(id, user_id) do
      render(conn, "declaration_request.json", declaration_request: declaration_request)
    end
  end

  def documents(conn, %{"id" => declaration_id}) do
    with {:ok, documents} <- DeclarationRequests.get_documents(declaration_id) do
      render(conn, "documents.json", documents: documents)
    end
  end
end
