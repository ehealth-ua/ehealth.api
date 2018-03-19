defmodule EHealth.Web.CabinetController do
  @moduledoc false

  use EHealth.Web, :controller

  import EHealth.Declarations.View, only: [render_declaration: 1]

  alias EHealth.Cabinet.API
  alias EHealth.DeclarationRequests
  alias EHealth.Declarations.API, as: Declarations
  alias EHealth.Persons
  alias EHealth.Guardian.Plug
  alias EHealth.Web.DeclarationRequestView

  action_fallback(EHealth.Web.FallbackController)

  def email_verification(conn, params) do
    with :ok <- API.send_email_verification(params) do
      render(conn, "raw.json", %{json: %{}})
    end
  end

  def email_validation(conn, _params) do
    with jwt <- Plug.current_token(conn),
         {:ok, new_jwt} <- API.validate_email_jwt(jwt) do
      render(conn, "email_validation.json", %{token: new_jwt})
    end
  end

  def registration(conn, params) do
    with jwt <- Plug.current_token(conn),
         {:ok, patient} <- API.create_patient(jwt, params, conn.req_headers) do
      conn
      |> put_status(:created)
      |> render("patient.json", patient: patient)
    end
  end

  def search_user(conn, params) do
    with :ok <- API.check_user_absence(params, conn.req_headers) do
      render(conn, "raw.json", %{json: %{}})
    end
  end

  def create_declaration_request(conn, params) do
    with {:ok, %{urgent_data: urgent_data, finalize: result}} <-
           DeclarationRequests.create_online(params, conn.req_headers) do
      conn
      |> assign(:urgent, urgent_data)
      |> put_view(DeclarationRequestView)
      |> render("declaration_request.json", declaration_request: result, display_hash: true)
    end
  end

  def update_person(conn, %{"id" => id} = params) do
    with {:ok, person} <- Persons.update(id, Map.delete(params, "id"), conn.req_headers) do
      render(conn, "show.json", person: person)
    end
  end

  def show_details(conn, _params) do
    with {:ok, person} <- Persons.get_person(conn.req_headers), do: render(conn, "show_details.json", person: person)
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
end
