defmodule EHealth.Web.EmployeeController do
  @moduledoc false

  use EHealth.Web, :controller

  alias Core.Employees, as: API
  alias Core.Employees.{Employee, EmployeeUpdater}
  alias Scrivener.Page

  action_fallback(EHealth.Web.FallbackController)

  def index(conn, params) do
    with %Page{} = paging <- API.list(Map.put(params, "is_active", true)) do
      render(
        conn,
        "index.json",
        employees: paging.entries,
        paging: paging
      )
    end
  end

  def show(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, employee} <- API.get_by_id(id, req_headers) do
      render(conn, "employee.json", employee: employee)
    end
  end

  def deactivate(%Plug.Conn{req_headers: req_headers} = conn, params) do
    with {:ok, employee} <- API.fetch_by_id(params["id"]),
         :ok <- check_legal_entity_id(params["legal_entity_id"], employee),
         {:ok, employee} <- EmployeeUpdater.deactivate(employee, "manual_employee_deactivate", req_headers) do
      render(conn, "employee.json", employee: employee)
    end
  end

  def employee_users(conn, %{"id" => employee_id}) do
    with {:ok, employee} <- API.get_by_id_with_users(employee_id) do
      render(conn, "employee_users_short.json", employee: employee)
    end
  end

  defp check_legal_entity_id(legal_entity_id, %Employee{legal_entity_id: legal_entity_id}), do: :ok
  defp check_legal_entity_id(_, _), do: {:error, :not_found}
end
