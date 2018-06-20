defmodule EHealth.Web.Cabinet.DeclarationRequestController do
  @moduledoc false

  use EHealth.Web, :controller
  alias EHealth.Cabinet.DeclarationRequests, as: CabinetDeclarationRequests
  alias EHealth.DeclarationRequests
  alias EHealth.Employees
  alias EHealth.Employees.Employee

  action_fallback(EHealth.Web.FallbackController)

  @ops_api Application.get_env(:ehealth, :api_resolvers)[:ops]

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, paging} <- CabinetDeclarationRequests.search(params, headers) do
      render(conn, "index.json", declaration_requests: paging.entries, paging: paging)
    end
  end

  def show(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    with {:ok, declaration_request} <- CabinetDeclarationRequests.get_by_id(id, headers),
         employee_id <- get_in(declaration_request.data, ["employee", "id"]),
         %Employee{} = employee <- Employees.get_by_id(employee_id),
         urgent_data = Map.take(declaration_request, [:authentication_method_current, :documents]),
         {:ok, %{"data" => %{"hash" => hash}}} = @ops_api.get_latest_block(headers) do
      conn
      |> assign(:urgent, urgent_data)
      |> render(
        "declaration_request.json",
        declaration_request: declaration_request,
        employee_speciality: employee.speciality,
        hash: hash
      )
    end
  end

  def create(%Plug.Conn{req_headers: headers} = conn, %{"employee_id" => employee_id} = params) do
    with {:ok, %{urgent_data: urgent_data, finalize: result}} <-
           DeclarationRequests.create_online(params, conn.req_headers),
         %Employee{} = employee <- Employees.get_by_id(employee_id),
         {:ok, %{"data" => %{"hash" => hash}}} = @ops_api.get_latest_block(headers) do
      conn
      |> assign(:urgent, urgent_data)
      |> render(
        "declaration_request.json",
        declaration_request: result,
        employee_speciality: employee.speciality,
        hash: hash
      )
    end
  end
end
