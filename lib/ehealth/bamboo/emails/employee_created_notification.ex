defmodule EHealth.Bamboo.Emails.EmployeeCreatedNotification do
  @moduledoc false

  use Confex, otp_app: :ehealth
  alias EHealth.Bamboo.Emails.Sender
  require Logger

  def send(_to, nil), do: Logger.error(fn -> "Email body is empty" end)
  def send(to, body) do
    Sender.send_email(to, body, config()[:from], config()[:subject])
  end
end
