defmodule IL.HashChain.Verification do
  @moduledoc false

  alias EHealth.Bamboo.Emails.Sender
  alias EHealth.Man.Templates.HashChainVerificationNotification, as: Template

  def send_failure_notification(mangled_blocks) do
    {:ok, body} = Template.render(mangled_blocks)
    email_config =
      :ehealth
      |> Confex.fetch_env!(:emails)
      |> Keyword.get(:hash_chain_verification_notification)
    Sender.send_email(email_config[:to], body, email_config[:from], email_config[:subject])
  end
end
