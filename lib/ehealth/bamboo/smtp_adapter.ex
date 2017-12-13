defmodule EHealth.Bamboo.SMTPAdapter do
  @moduledoc false
  @behaviour Bamboo.Adapter
  alias Bamboo.SMTPAdapter

  def deliver(email, config),
    do: SMTPAdapter.deliver(email, config)

  def handle_config(_config) do
    :ehealth
    |> Confex.fetch_env!(EHealth.Bamboo.SMTPMailer)
    |> Enum.into(%{})
    |> SMTPAdapter.handle_config()
  end
end
