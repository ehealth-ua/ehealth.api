defmodule EHealth.Web.EmployeeRequestController do
  @moduledoc false

  use EHealth.Web, :controller
  alias Scrivener.Page
  alias EHealth.EmployeeRequests, as: API
  alias EHealth.API.Mithril
  alias EHealth.EmployeeRequests.EmployeeRequest, as: Request
  alias EHealth.LegalEntities

  action_fallback EHealth.Web.FallbackController

  def index(conn, params) do
    with {%Page{} = paging, references} <- API.list(params) do
      render(conn, "index.json",
        employee_requests: paging.entries,
        references: references,
        paging: paging
      )
    end
  end

  def create(%Plug.Conn{req_headers: req_headers} = conn, params) do
    client_id = get_client_id(req_headers)
    params = put_in(params, ["employee_request", "legal_entity_id"], client_id)
    with {:ok, employee_request} <- API.create(params) do
      render(conn, "show.json",
        employee_request: employee_request,
        legal_entity: get_legal_entity(employee_request)
      )
    end
  end

  def show(conn, %{"id" => id}) do
    employee_request = API.get_by_id!(id)

    conn
    |> put_urgent_user_id(employee_request)
    |> render("show.json",
      employee_request: employee_request,
      legal_entity: get_legal_entity(employee_request)
    )
  end

  def create_user(%Plug.Conn{req_headers: req_headers} = conn, params) do
    with {:ok, %{"meta" => %{}} = response} <- API.create_user_by_employee_request(params, req_headers) do
      proxy(conn, response)
    end
  end

  def approve(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with :ok <- API.check_employee_request(req_headers, id) do
      with {:ok, employee_request} <- API.approve(id, req_headers) do
        render(conn, "show.json",
          employee_request: employee_request,
          legal_entity: get_legal_entity(employee_request)
        )
      end
    end
  end

  def reject(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with :ok <- API.check_employee_request(req_headers, id) do
      with {:ok, employee_request} <- API.reject(id) do
        render(conn, "show.json",
          employee_request: employee_request,
          legal_entity: get_legal_entity(employee_request)
        )
      end
    end
  end

  defp get_legal_entity(%Request{} = request) do
    LegalEntities.get_by_id(request.data["legal_entity_id"]) || %{}
  end

  defp put_urgent_user_id(conn, %Request{data: data}) do
    email = get_in(data, ["party", "email"])

    %{email: email}
    |> Mithril.search_user()
    |> process_user_id(conn)
  end

  defp process_user_id({:ok, body}, conn) do
    body
    |> Map.get("data")
    |> set_user_id(conn)
  end
  defp process_user_id({:error, _reason}, conn), do: conn

  defp set_user_id([%{"id" => user_id}], conn), do: assign(conn, :urgent, %{"user_id" => user_id})
  defp set_user_id(_, conn), do: conn
end
