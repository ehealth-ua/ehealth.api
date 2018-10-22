use Mix.Config

config :graphql, GraphQLWeb.Endpoint,
  http: [port: 4001],
  server: false

config :logger, level: :debug
config :ex_unit, capture_log: true
