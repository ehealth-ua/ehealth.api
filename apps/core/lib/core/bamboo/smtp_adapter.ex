defmodule Core.Bamboo.SMTPAdapter do
  @moduledoc false

  @behaviour Bamboo.Adapter

  alias Bamboo.SMTPAdapter

  def deliver(email, config), do: SMTPAdapter.deliver(email, config)

  def handle_config(_config) do
    :core
    |> Confex.fetch_env!(Core.Bamboo.SMTPMailer)
    |> Enum.into(%{})
    |> SMTPAdapter.handle_config()
  end
end
