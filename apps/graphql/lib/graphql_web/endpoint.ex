defmodule GraphQLWeb.Endpoint do
  @moduledoc false

  use Phoenix.Endpoint, otp_app: :graphql

  alias Confex.Resolver
  alias GraphQLWeb.Plugs.Context

  @scope_header "x-consumer-scope"

  plug(Plug.RequestId)
  plug(LoggerJSON.Plug, level: Logger.level())

  plug(
    Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  )

  plug(Context, scope_header: @scope_header)

  plug(
    Absinthe.Plug,
    schema: GraphQLWeb.Schema,
    json_codec: Jason
  )

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

  def scope_header, do: @scope_header
end
