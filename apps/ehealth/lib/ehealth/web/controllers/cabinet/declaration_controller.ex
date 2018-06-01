defmodule EHealth.Web.Cabinet.DeclarationController do
  use EHealth.Web, :controller

  alias EHealth.API.OPS
  alias EHealth.DeclarationRequests
  alias EHealth.Declarations.API, as: Declarations
  alias EHealth.Web.DeclarationRequestView
  alias EHealth.Cabinet.Requests.DeclarationsSearch
  alias EHealth.Web.DeclarationView
  require Logger

  action_fallback(EHealth.Web.FallbackController)

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    with %Ecto.Changeset{valid?: true} <- DeclarationsSearch.changeset(params),
         {:ok, %{declarations: _, declaration_references: _, person: _, paging: _} = response_data} <-
           Declarations.get_person_declarations(params, headers) do
      render(conn, DeclarationView, "cabinet_index.json", response_data)
    end
  end

  def create_declaration_request(conn, params) do
    with {:ok, %{urgent_data: urgent_data, finalize: result}} <-
           DeclarationRequests.create_online(params, conn.req_headers),
         {:ok, %{"data" => %{"hash" => hash}}} = OPS.get_latest_block() do
      conn
      |> assign(:urgent, urgent_data)
      |> put_view(DeclarationRequestView)
      |> render("declaration_request.json", declaration_request: result, hash: hash)
    end
  end

  def approve_declaration_request(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    with {:ok, %{declaration_request: declaration_request}} <- DeclarationRequests.approve(id, headers) do
      conn
      |> put_view(DeclarationRequestView)
      |> render("declaration_request.json", declaration_request: declaration_request)
    else
      {:error, _, %{"meta" => %{"code" => 404}}, _} ->
        Logger.error(fn ->
          Jason.encode!(%{
            "log_type" => "error",
            "message" => "Phone was not found for declaration request #{id}",
            "request_id" => Logger.metadata()[:request_id]
          })
        end)

        {:error, %{"type" => "internal_error"}}

      {:error, :verification, {:documents_not_uploaded, reason}, _} ->
        {:conflict, "Documents #{Enum.join(reason, ", ")} is not uploaded"}

      {:error, :verification, {:ael_bad_response, _}, _} ->
        {:error, %{"type" => "internal_error"}}

      {:error, :verification, {:conflict, message}, _} ->
        {:error, {:conflict, message}}

      {:error, :verification, {:"422", message}, _} ->
        {:error, {:"422", message}}

      {:error, _, %{"meta" => _} = error, _} ->
        {:error, error}

      {:error, error} ->
        {:error, error}
    end
  end

  def terminate_declaration(conn, %{"id" => id} = params) do
    user_id = get_consumer_id(conn.req_headers)

    with {:ok, declaration} <- Declarations.terminate(id, user_id, params, conn.req_headers) do
      render(conn, DeclarationView, "show.json", declaration: declaration)
    end
  end

  def show_declaration(conn, %{"id" => id}) do
    with {:ok, declaration} <- Declarations.get_declaration(id, conn.req_headers) do
      render(conn, DeclarationView, "show.json", declaration: declaration)
    end
  end
end
