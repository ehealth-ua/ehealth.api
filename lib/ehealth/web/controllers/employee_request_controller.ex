defmodule EHealth.Web.EmployeeRequestController do
  @moduledoc false

  use EHealth.Web, :controller
  alias EHealth.EmployeeRequest.API
  alias EHealth.Man.Templates.EmployeeRequestInvitation, as: EmployeeRequestInvitationTemplate
  alias EHealth.Bamboo.Emails.EmployeeRequestInvitation, as: EmployeeRequestInvitationEmail
  require Logger

  action_fallback EHealth.Web.FallbackController

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
end
