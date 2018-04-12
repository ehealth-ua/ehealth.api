defmodule EHealth.Web.EmployeeController do
  @moduledoc false

  use EHealth.Web, :controller

  alias Scrivener.Page
  alias EHealth.Employees, as: API
  alias EHealth.Employees.EmployeeUpdater

  action_fallback(EHealth.Web.FallbackController)

  @report_api Application.get_env(:ehealth, :api_resolvers)[:report]

  def index(%Plug.Conn{req_headers: req_headers} = conn, params) do
    with %Page{} = paging <- API.list(Map.put(params, "is_active", true)),
         {:ok, %{"data" => declaration_count_data}} <-
           @report_api.get_declaration_count(Enum.map(paging.entries, &Map.get(&1, :party_id)), req_headers) do
      render(
        conn,
        "index.json",
        employees: paging.entries,
        paging: paging,
        declaration_count_data: declaration_count_data
      )
    end
  end

  def show(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, employee} <- API.get_by_id(id, req_headers),
         {:ok, %{"data" => declaration_count_data}} <-
           @report_api.get_declaration_count([employee.party_id], req_headers) do
      render(conn, "employee.json", employee: employee, declaration_count_data: declaration_count_data)
    end
  end

  def deactivate(%Plug.Conn{req_headers: req_headers} = conn, params) do
    with {:ok, employee} <- EmployeeUpdater.deactivate(params, req_headers),
         {:ok, %{"data" => declaration_count_data}} <-
           @report_api.get_declaration_count([employee.party_id], req_headers) do
      render(conn, "employee.json", employee: employee, declaration_count_data: declaration_count_data)
    end
  end
end
