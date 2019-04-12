use Mix.Config

# General application configuration
config :graphql,
  env: Mix.env(),
  namespace: GraphQL

# Configures the endpoint
config :graphql, GraphQL.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "CYmgC8ImSRDRzR8UuogkPi3LY9xnvdta6S4pJmKDSQPnqRF9p5PNNS11eE7a2Uc5",
  debug_errors: false,
  render_errors: [
    view: GraphQL.Resolvers.Helpers.ErrorView,
    accepts: ~w(json)
  ],
  instrumenters: [LoggerJSON.Phoenix.Instruments]

# Config Jason as default Json encoder for Phoenix
config :phoenix, :format_encoders, json: Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
