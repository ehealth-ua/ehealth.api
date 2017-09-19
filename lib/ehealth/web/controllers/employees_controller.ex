defmodule EHealth.Web.EmployeeController do
  @moduledoc false

  use EHealth.Web, :controller

  alias Scrivener.Page
  alias EHealth.Employee.API
  alias EHealth.Employee.EmployeeUpdater

  action_fallback EHealth.Web.FallbackController

  def index(conn, params) do
    with %Page{} = paging <- API.get_employees(params) do
      render(conn, "index.json", employees: paging.entries, paging: paging)
    end
  end

  def show(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, employee} <- API.get_employee_by_id(id, req_headers) do
      render(conn, "employee.json", employee: employee)
    end
  end

  def deactivate(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, employee} <- EmployeeUpdater.deactivate(id, req_headers) do
      render(conn, "employee.json", employee: employee)
    end
  end
end
