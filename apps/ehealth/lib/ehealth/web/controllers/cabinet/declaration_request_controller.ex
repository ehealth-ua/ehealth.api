defmodule EHealth.Web.Cabinet.DeclarationRequestController do
  @moduledoc false

  use EHealth.Web, :controller
  alias Core.Cabinet.DeclarationRequests, as: CabinetDeclarationRequests
  alias Core.DeclarationRequests
  alias Core.V2.DeclarationRequests, as: DeclarationRequestsV2
  alias Core.Employees
  alias Core.Employees.Employee
  alias EHealth.Web.DeclarationRequestView
  require Logger

  action_fallback(EHealth.Web.FallbackController)

  @ops_api Application.get_env(:core, :api_resolvers)[:ops]

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
        employee_speciality: employee.speciality["speciality"],
        hash: hash
      )
    end
  end

  def create(%Plug.Conn{req_headers: headers} = conn, %{"employee_id" => employee_id} = params) do
    with {:ok, %{urgent_data: urgent_data, finalize: result}} <-
           DeclarationRequestsV2.create_online(params, conn.req_headers),
         %Employee{} = employee <- Employees.get_by_id(employee_id),
         {:ok, %{"data" => %{"hash" => hash}}} = @ops_api.get_latest_block(headers) do
      conn
      |> assign(:urgent, urgent_data)
      |> render(
        "declaration_request.json",
        declaration_request: result,
        employee_speciality: employee.speciality["speciality"],
        hash: hash
      )
    end
  end

  def approve(%Plug.Conn{req_headers: headers} = conn, %{"id" => id}) do
    with {:ok, %{declaration_request: declaration_request}} <- DeclarationRequests.approve(id, headers) do
      conn
      |> put_view(DeclarationRequestView)
      |> render("declaration_request.json", declaration_request: declaration_request)
    else
      {:error, _, %{"meta" => %{"code" => 404}}, _} ->
        Logger.error(fn ->
          Jason.encode!(%{
            "log_type" => "error",
            "message" => "Phone was not found for declaration request #{id}",
            "request_id" => Logger.metadata()[:request_id]
          })
        end)

        {:error, %{"type" => "internal_error"}}

      {:error, :verification, {:documents_not_uploaded, reason}, _} ->
        {:conflict, "Documents #{Enum.join(reason, ", ")} is not uploaded"}

      {:error, :verification, {:ael_bad_response, _}, _} ->
        {:error, %{"type" => "internal_error"}}

      {:error, :verification, {:conflict, message}, _} ->
        {:error, {:conflict, message}}

      {:error, :verification, {:"422", message}, _} ->
        {:error, {:"422", message}}

      {:error, _, %{"meta" => _} = error, _} ->
        {:error, error}

      {:error, error} ->
        {:error, error}
    end
  end
end
