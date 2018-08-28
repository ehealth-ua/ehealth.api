defmodule Casher.Web.Endpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :casher
  alias Confex.Resolver

  plug(Plug.Logger)

  plug(Plug.RequestId)
  plug(Plug.LoggerJSON, level: Logger.level())

  plug(
    Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(EView)

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  plug(Casher.Router)

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  @spec init(term, term) :: {:ok, term}
  def init(_key, config) do
    config = Resolver.resolve!(config)

    unless config[:secret_key_base] do
      raise "Set SECRET_KEY environment variable!"
    end

    {:ok, config}
  end
end
