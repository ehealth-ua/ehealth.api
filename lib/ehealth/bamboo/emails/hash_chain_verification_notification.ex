defmodule EHealth.Bamboo.Emails.HashChainVeriricationNotification do
  @moduledoc false

  use Confex, otp_app: :ehealth
  alias EHealth.Bamboo.Emails.Sender

  def send(body) do
    Sender.send_email(config()[:to], body, config()[:from], config()[:subject])
  end
end
