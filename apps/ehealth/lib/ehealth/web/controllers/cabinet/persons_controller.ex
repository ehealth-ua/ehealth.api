defmodule EHealth.Web.Cabinet.PersonsController do
  use EHealth.Web, :controller

  alias EHealth.Persons

  action_fallback(EHealth.Web.FallbackController)

  def update_person(conn, %{"id" => id} = params) do
    with {:ok, person} <- Persons.update(id, Map.delete(params, "id"), conn.req_headers) do
      render(conn, "show.json", person: person)
    end
  end

  def personal_info(conn, _params) do
    with {:ok, person} <- Persons.get_person(conn.req_headers), do: render(conn, "personal_info.json", person: person)
  end

  def person_details(conn, _) do
    with {:ok, person} <- Persons.get_details(conn.req_headers) do
      render(conn, "person_details.json", person: person)
    end
  end
end
