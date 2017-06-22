defmodule EHealth.Bamboo.Emails.EmployeeRequestInvitation do
  @moduledoc false

  use Confex, otp_app: :ehealth
  alias EHealth.Bamboo.Emails.Sender
  require Logger

  def send(to, body) do
    Sender.send_email(to, body, config()[:from], config()[:subject])
  end
end
