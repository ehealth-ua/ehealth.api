defmodule EHealth.Bamboo.MailgunAdapter do
  @moduledoc false
  @behaviour Bamboo.Adapter
  alias Bamboo.MailgunAdapter

  def deliver(email, config),
    do: MailgunAdapter.deliver(email, config)

  def handle_config(_config) do
    :ehealth
    |> Confex.fetch_env!(EHealth.Bamboo.MailgunMailer)
    |> Enum.into(%{})
    |> MailgunAdapter.handle_config()
  end
end
