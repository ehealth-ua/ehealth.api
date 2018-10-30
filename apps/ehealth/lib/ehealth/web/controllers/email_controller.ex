defmodule EHealth.Web.EmailController do
  @moduledoc false

  use EHealth.Web, :controller

  alias Core.Email
  alias Core.Validators.JsonSchema

  action_fallback(EHealth.Web.FallbackController)

  def send(conn, params) do
    with :ok <- JsonSchema.validate(:email_internal_request, params),
         :ok <- Email.send(params) do
      conn
      |> put_status(200)
      |> render("email_sent.json")
    end
  end
end
