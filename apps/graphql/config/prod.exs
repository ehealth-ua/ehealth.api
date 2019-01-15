use Mix.Config

config :graphql, GraphQLWeb.Endpoint,
  load_from_system_env: true,
  http: [port: {:system, "PORT", "80"}],
  url: [
    host: {:system, "HOST", "localhost"},
    port: {:system, "PORT", "80"}
  ],
  secret_key_base: {:system, "SECRET_KEY"},
  debug_errors: false,
  code_reloader: false

config :logger, level: :info

# Do not log passwords, card data and tokens
config :phoenix, :filter_parameters, ["password", "secret", "token", "password_confirmation", "card", "pan", "cvv"]
config :phoenix, :serve_endpoints, true
