defmodule EHealth.Web.Cabinet.DeclarationController do
  use EHealth.Web, :controller

  import EHealth.Declarations.View, only: [render_declaration: 1]

  alias EHealth.API.OPS
  alias EHealth.DeclarationRequests
  alias EHealth.Declarations.API, as: Declarations
  alias EHealth.Cabinet.API.DeclarationsAPI
  alias EHealth.Web.DeclarationRequestView
  alias EHealth.Cabinet.Requests.DeclarationsSearch

  action_fallback(EHealth.Web.FallbackController)

  def list_declarations(%Plug.Conn{req_headers: headers} = conn, params) do
    with %Ecto.Changeset{valid?: true} <- DeclarationsSearch.changeset(params),
         {:ok, %{declarations: _, employees: _, person: _, paging: _} = response_data} <-
           DeclarationsAPI.get_declarations(params, headers) do
      render(conn, "list_declarations.json", response_data)
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

  def terminate_declaration(conn, %{"id" => id} = params) do
    user_id = get_consumer_id(conn.req_headers)

    with {:ok, declaration} <- Declarations.terminate(id, user_id, params, conn.req_headers) do
      response =
        declaration
        |> render_declaration()
        |> Poison.encode!()

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, response)
    end
  end

  def show_declaration(conn, %{"id" => id}) do
    with {:ok, declaration} <- Declarations.get_declaration(id, conn.req_headers) do
      response =
        declaration
        |> render_declaration()
        |> Poison.encode!()

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, response)
    end
  end
end
