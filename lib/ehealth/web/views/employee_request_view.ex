defmodule EHealth.Web.EmployeeRequestView do
  @moduledoc false

  use EHealth.Web, :view
  alias EHealth.Web.EmployeeRequestView

  def render("show.json", %{employee_request: employee_request}) do
    render_one(employee_request, EmployeeRequestView, "employee_request.json")
  end

  def render("employee_request.json", employee_request), do: employee_request
end
