defmodule IL.HashChain.Verification do
  @moduledoc false

  alias EHealth.Bamboo.Emails.HashChainVeriricationNotification, as: Email
  alias EHealth.Man.Templates.HashChainVerificationNotification, as: Template

  def send_failure_notification(mangled_blocks) do
    {:ok, body} = Template.render(mangled_blocks)
    Email.send(body)
  end
end
