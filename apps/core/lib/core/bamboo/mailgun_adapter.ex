defmodule Core.Bamboo.MailgunAdapter do
  @moduledoc false

  @behaviour Bamboo.Adapter

  alias Bamboo.MailgunAdapter

  def deliver(email, config), do: MailgunAdapter.deliver(email, config)

  def handle_config(_config) do
    :core
    |> Confex.fetch_env!(Core.Bamboo.MailgunMailer)
    |> Enum.into(%{})
    |> MailgunAdapter.handle_config()
  end
end
