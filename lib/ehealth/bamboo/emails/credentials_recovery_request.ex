defmodule EHealth.Bamboo.Emails.CredentialsRecoveryRequest do
  @moduledoc false
  alias EHealth.Bamboo.Emails.Sender

  def send(to, body),
    do: Sender.send_email(to, body, config()[:from], config()[:subject])

  defp config,
    do: Confex.get_map(:ehealth, __MODULE__)
end
