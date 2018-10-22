use Mix.Config

config :graphql, GraphQLWeb.Endpoint,
  http: [port: 4001],
  server: false

config :logger, level: :info
config :ex_unit, capture_log: true
