defmodule EHealth.Web.MisController do
  @moduledoc false
  use EHealth.Web, :controller

  alias EHealth.EmployeeRequests.EmployeeRequest
  alias EHealth.Repo

  action_fallback(EHealth.Web.FallbackController)

  def employee_request(conn, %{"id" => id}) do
    with %EmployeeRequest{} = request <- Repo.get(EmployeeRequest, id) do
      render(conn, "employee_request.json", %{employee_request: request})
    end
  end
end
