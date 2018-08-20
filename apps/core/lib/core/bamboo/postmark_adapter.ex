defmodule Core.Bamboo.PostmarkAdapter do
  @moduledoc false

  @behaviour Bamboo.Adapter

  alias Bamboo.PostmarkAdapter

  def deliver(email, config), do: PostmarkAdapter.deliver(email, config)

  def handle_config(_config) do
    :core
    |> Confex.fetch_env!(Core.Bamboo.PostmarkMailer)
    |> Enum.into(%{})
    |> PostmarkAdapter.handle_config()
  end
end
