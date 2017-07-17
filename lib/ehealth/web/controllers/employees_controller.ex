defmodule EHealth.Web.EmployeesController do
  @moduledoc false

  use EHealth.Web, :controller

  alias EHealth.Employee.API
  alias EHealth.Employee.EmployeeUpdater

  action_fallback EHealth.Web.FallbackController

  def index(%Plug.Conn{req_headers: req_headers} = conn, params) do
    with {:ok, %{"meta" => %{}} = response} <- API.get_employees(params, req_headers) do
      proxy(conn, response)
    end
  end

  def show(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, %{employee: %{"meta" => %{}} = response}} <- API.get_employee_by_id(id, req_headers) do
      proxy(conn, response)
    end
  end

  def deactivate(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, {:ok, %{"meta" => %{}} = response}} <- EmployeeUpdater.deactivate(id, req_headers) do
      proxy(conn, response)
    end
  end
end
