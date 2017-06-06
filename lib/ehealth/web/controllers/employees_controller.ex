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

  def show(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, %{"meta" => %{}, "data" => data} = response} <- PRM.get_employee_by_id(id, req_headers) do
      client_id = get_client_id(req_headers)
      with :ok <- check_employee(client_id, data) do
        proxy(conn, response)
      end
    end
  end

  defp check_employee(nil, _employee), do: :ok
  defp check_employee(client_id, employee) do
    case client_id == Map.get(employee, "legal_entity_id") do
      true -> :ok
      _ -> {:error, :not_found}
    end
  end
end
