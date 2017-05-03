defmodule EHealth.Web.EmployeeRequestController do
  @moduledoc false

  use EHealth.Web, :controller
  alias EHealth.EmployeeRequest.API
  alias EHealth.Man.Templates.EmployeeRequestInvitation
  require Logger

  action_fallback EHealth.Web.FallbackController

  def create(conn, params) do
    with {:ok, employee_request} <- API.create_employee_request(params) do
      employee_request
      |> Map.get(:id)
      |> EmployeeRequestInvitation.render()
      |> Logger.debug() # ToDo: replace with email sending when postboy is ready

      render(conn, "show.json", employee_request: employee_request)
    end
  end
end
