defmodule EHealth.Bamboo.Emails.CredentialsRecoveryRequest do
  @moduledoc false
  alias EHealth.Bamboo.Emails.Sender

  def send(to, body),
    do: Sender.send_email(to, body, config()[:from], config()[:subject])

  defp config,
    do: Confex.fetch_env!(:ehealth, __MODULE__)
end
