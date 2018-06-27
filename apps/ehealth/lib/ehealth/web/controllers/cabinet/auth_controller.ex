defmodule EHealth.Web.Cabinet.AuthController do
  use EHealth.Web, :controller

  alias EHealth.Cabinet.API, as: CabinetAPI
  alias EHealth.Guardian.Plug
  alias Scrivener.Page

  action_fallback(EHealth.Web.FallbackController)

  def email_verification(conn, params) do
    with {:ok, jwt} <- CabinetAPI.send_email_verification(params, conn.req_headers) do
      conn
      |> assign_token(jwt)
      |> render("raw.json", %{json: %{}})
    end
  end

  defp assign_token(conn, jwt) do
    case Confex.fetch_env!(:ehealth, :sensitive_data_in_response) do
      true -> assign_urgent(conn, :token, jwt)
      false -> conn
    end
  end

  def email_validation(conn, _params) do
    with jwt <- Plug.current_token(conn),
         {:ok, new_jwt} <- CabinetAPI.validate_email_jwt(jwt, conn.req_headers) do
      render(conn, "email_validation.json", %{token: new_jwt})
    end
  end

  def search_user(conn, params) do
    with jwt <- Plug.current_token(conn),
         :ok <- CabinetAPI.check_user_absence(jwt, params, conn.req_headers) do
      render(conn, "raw.json", %{json: %{}})
    end
  end

  def registration(conn, params) do
    system_user = Confex.fetch_env!(:ehealth, :system_user)

    with jwt <- Plug.current_token(conn),
         conn <- put_req_header(conn, "x-consumer-id", system_user),
         {:ok, patient} <- CabinetAPI.create_patient(jwt, params, conn.req_headers) do
      conn
      |> put_status(:created)
      |> render("patient.json", patient: patient)
    end
  end

  def get_authentication_factor(conn, _) do
    with %Page{} = paging <- CabinetAPI.get_user_authentication_factor(conn.req_headers) do
      render(conn, "authentication_factors_list.json", authentication_factors: paging.entries, paging: paging)
    end
  end
end
