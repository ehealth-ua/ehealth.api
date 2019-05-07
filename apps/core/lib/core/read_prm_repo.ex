defmodule Core.ReadPRMRepo do
  @moduledoc false

  @paginator_options [max_page_size: 500, page_size: 50]

  use Ecto.Repo, otp_app: :core, adapter: Ecto.Adapters.Postgres
  use Scrivener, @paginator_options
  use EctoTrail
  alias Scrivener.Config

  def paginator_options(options \\ []) do
    Config.new(__MODULE__, @paginator_options, options)
  end
end
