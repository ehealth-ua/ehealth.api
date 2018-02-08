defmodule EHealth.Web.MisView do
  @moduledoc false

  use EHealth.Web, :view

  def render("employee_request.json", %{employee_request: employee_request}) do
    %{
      id: employee_request.id,
      employee_id: employee_request.employee_id,
      status: employee_request.status,
      updated_at: employee_request.updated_at
    }
  end
end
