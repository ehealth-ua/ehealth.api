defmodule EHealth.Web.Cabinet.DeclarationController do
  use EHealth.Web, :controller

  alias Core.Declarations.API, as: Declarations
  alias Core.Cabinet.Requests.DeclarationsSearch
  alias EHealth.Web.DeclarationView

  action_fallback(EHealth.Web.FallbackController)

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    with %Ecto.Changeset{valid?: true} <- DeclarationsSearch.changeset(params),
         {:ok, %{declarations: _, declaration_references: _, person: _, paging: _} = response_data} <-
           Declarations.get_person_declarations(params, headers) do
      render(conn, DeclarationView, "cabinet_index.json", response_data)
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
