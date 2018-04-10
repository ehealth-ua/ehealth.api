defmodule EHealth.Web.Cabinet.AuthController do
  use EHealth.Web, :controller

  alias EHealth.Cabinet.API, as: CabinetAPI
  alias EHealth.Guardian.Plug

  action_fallback(EHealth.Web.FallbackController)

  def email_verification(conn, params) do
    with :ok <- CabinetAPI.send_email_verification(params, conn.req_headers) do
      render(conn, "raw.json", %{json: %{}})
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
end
