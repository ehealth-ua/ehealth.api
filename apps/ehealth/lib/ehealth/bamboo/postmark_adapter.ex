defmodule EHealth.Bamboo.PostmarkAdapter do
  @moduledoc false
  @behaviour Bamboo.Adapter
  alias Bamboo.PostmarkAdapter

  def deliver(email, config), do: PostmarkAdapter.deliver(email, config)

  def handle_config(_config) do
    :ehealth
    |> Confex.fetch_env!(EHealth.Bamboo.PostmarkMailer)
    |> Enum.into(%{})
    |> PostmarkAdapter.handle_config()
  end
end
