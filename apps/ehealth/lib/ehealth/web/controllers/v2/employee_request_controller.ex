defmodule EHealth.Web.V2.EmployeeRequestController do
  @moduledoc false

  use EHealth.Web, :controller
  alias EHealth.EmployeeRequests
  alias EHealth.Web.EmployeeRequestView

  action_fallback(EHealth.Web.FallbackController)

  def create(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, employee_request, references} <- EmployeeRequests.create_signed(params, headers) do
      render(
        conn,
        EmployeeRequestView,
        "show.json",
        employee_request: employee_request,
        references: references
      )
    end
  end
end
