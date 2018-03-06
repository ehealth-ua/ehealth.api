defmodule EHealth.Web.CabinetController do
  @moduledoc false

  use EHealth.Web, :controller

  alias EHealth.Cabinet.API
  alias EHealth.Persons

  action_fallback(EHealth.Web.FallbackController)

  def email_verification(conn, params) do
    with :ok <- API.send_email_verification(params) do
      render(conn, "email_verification.json", %{})
    end
  end

  def update_person(conn, %{"id" => id} = params) do
    with {:ok, person} <- Persons.update(id, Map.delete(params, "id"), conn.req_headers) do
      render(conn, "show.json", person: person)
    end
  end
end
