defmodule EHealth.Man.Templates.EmployeeRequestUpdateInvitation do
  @moduledoc false

  use Confex, otp_app: :ehealth
  alias EHealth.Man.Templates.EmployeeRequestInvitation
  alias EHealth.EmployeeRequests.EmployeeRequest, as: Request

  def render(%Request{} = request) do
    EmployeeRequestInvitation.render(request)
  end
end
