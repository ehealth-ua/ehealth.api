defmodule EHealth.Web.PersonsController do
  @moduledoc false
  use EHealth.Web, :controller
  alias EHealth.Declarations.Person

  action_fallback EHealth.Web.FallbackController

  def person_declarations(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, %{"meta" => %{}} = response} <- Person.get_person_declaration(id, req_headers) do
      proxy(conn, response)
    end
  end
end
