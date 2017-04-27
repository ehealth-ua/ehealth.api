defmodule EHealth.Web.EmployeeRequestController do
  @moduledoc false

  use EHealth.Web, :controller
  alias EHealth.EmployeeRequest.API

  action_fallback EHealth.Web.FallbackController

  def create(conn, params) do
    with {:ok, employee_request} <- API.create_employee_request(params) do
      render(conn, "show.json", employee_request: employee_request)
    end
  end
end
