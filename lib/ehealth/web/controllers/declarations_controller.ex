defmodule EHealth.Web.DeclarationsController do
  @moduledoc false

  use EHealth.Web, :controller

  alias EHealth.API.OPS
  alias EHealth.Declarations.API

  action_fallback EHealth.Web.FallbackController

  def index(%Plug.Conn{req_headers: req_headers} = conn, params) do
    with {:ok, %{"meta" => %{}} = response} <- OPS.get_declarations(params, req_headers) do
      proxy(conn, response)
    end
  end

  def show(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, %{"meta" => %{}} = response} <- API.get_declaration_by_id(id, req_headers) do
      proxy(conn, response)
    end
  end
end
