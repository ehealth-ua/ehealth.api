defmodule EHealth.Web.PersonController do
  @moduledoc false
  use EHealth.Web, :controller

  alias EHealth.API.MPI
  alias EHealth.DeclarationRequest
  alias EHealth.Declarations.Person

  action_fallback EHealth.Web.FallbackController

  @auth_na DeclarationRequest.authentication_method(:na)

  def person_declarations(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, %{"meta" => %{}} = response} <- Person.get_person_declaration(id, req_headers) do
      proxy(conn, response)
    end
  end

  def search_persons(conn, params) do
    with {:ok, %{"meta" => %{}} = response} <- MPI.search(params, conn.req_headers) do
      proxy(conn, response)
    end
  end

  def reset_authentication_method(conn, %{"id" => id}) do
    update_data = %{authentication_methods: [%{type: @auth_na}]}
    with {:ok, %{"meta" => %{}} = response} <- MPI.update_person(id, update_data, conn.req_headers) do
      proxy(conn, response)
    end
  end
end
