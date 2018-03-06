defmodule EHealth.Web.EmailController do
  @moduledoc false

  use EHealth.Web, :controller

  alias EHealth.Email

  action_fallback(EHealth.Web.FallbackController)

  def send(conn, params) do
    with :ok <- Email.send(params) do
      conn
      |> put_status(200)
      |> render("email_sent.json")
    end
  end
end
