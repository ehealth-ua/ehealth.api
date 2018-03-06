defmodule EHealth.Web.CabinetController do
  @moduledoc false

  use EHealth.Web, :controller

  alias EHealth.Cabinet.API

  action_fallback(EHealth.Web.FallbackController)

  def email_verification(conn, params) do
    with :ok <- API.send_email_verification(params) do
      render(conn, "email_verification.json", %{})
    end
  end
end
