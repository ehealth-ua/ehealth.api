defmodule EHealth.Web.EmployeeRequestController do
  @moduledoc false

  use EHealth.Web, :controller
  alias EHealth.EmployeeRequest.API
  alias EHealth.Man.Templates.EmployeeRequestInvitation, as: EmployeeRequestInvitationTemplate
  alias EHealth.Bamboo.Emails.EmployeeRequestInvitation, as: EmployeeRequestInvitationEmail
  alias EHealth.API.Mithril
  alias EHealth.EmployeeRequest
  require Logger

  action_fallback EHealth.Web.FallbackController

  def show(conn, %{"id" => id}) do
    employee_request = API.get_by_id!(id)

    conn
    |> put_urgent_user_id(employee_request)
    |> render("show.json", employee_request: employee_request)
  end

  def index(conn, params) do
    with {employee_requests, %Ecto.Paging{} = paging} <- API.list_employee_requests(params) do
      render(conn, "index.json", employee_requests: employee_requests, paging: paging)
    end
  end

  def create(conn, params) do
    with {:ok, employee_request} <- API.create_employee_request(params) do
      email_body =
        employee_request
        |> Map.get(:id)
        |> EmployeeRequestInvitationTemplate.render()

      try do
        params
        |> get_in(["employee_request", "party", "email"])
        |> EmployeeRequestInvitationEmail.send(email_body) # ToDo: use postboy when it is ready
      rescue
        e -> Logger.error(e.message)
      end

      render(conn, "show.json", employee_request: employee_request)
    end
  end

  def approve(%Plug.Conn{req_headers: req_headers} = conn, %{"id" => id}) do
    with {:ok, employee_request} <- API.approve_employee_request(id, req_headers) do
      render(conn, "show.json", employee_request: employee_request)
    end
  end

  def reject(conn, %{"id" => id}) do
    with {:ok, employee_request} <- API.reject_employee_request(id) do
      render(conn, "show.json", employee_request: employee_request)
    end
  end

  defp put_urgent_user_id(conn, %EmployeeRequest{data: data}) do
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
