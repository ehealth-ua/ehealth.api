defmodule EHealth.Man.Templates.EmployeeRequestInvitation do
  @moduledoc false

  use Confex, otp_app: :ehealth
  alias EHealth.API.Man

  def render(employee_request_id) do
    Man.render_template(config()[:id], %{
      format: config()[:format],
      activation_link: config()[:activation_link] <> employee_request_id
    })
  end
end
