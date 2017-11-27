defmodule EHealth.Web.EmployeeController do
  @moduledoc false

  use EHealth.Web, :controller

  alias Scrivener.Page
  alias EHealth.Employees, as: API
  alias EHealth.Employees.EmployeeUpdater

  action_fallback EHealth.Web.FallbackController

  def index(conn, params) do
    with %Page{} = paging <- API.list(Map.put(params, "is_active", true)) do
      render(conn, "index.json", employees: paging.entries, paging: paging)
    end
  end

  def show(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, employee} <- API.get_by_id(id, req_headers) do
      render(conn, "employee.json", employee: employee)
    end
  end

  def deactivate(%Plug.Conn{req_headers: req_headers} = conn, params) do
    with {:ok, employee} <- EmployeeUpdater.deactivate(params, req_headers) do
      render(conn, "employee.json", employee: employee)
    end
  end
end
