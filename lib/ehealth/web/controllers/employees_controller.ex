defmodule EHealth.Web.EmployeesController do
  @moduledoc false

  use EHealth.Web, :controller

  alias EHealth.API.PRM

  action_fallback EHealth.Web.FallbackController

  def index(%Plug.Conn{req_headers: req_headers} = conn, params) do
    with {:ok, %{"meta" => %{}} = response} <- PRM.get_employees(params, req_headers) do
      proxy(conn, response)
    end
  end

end
