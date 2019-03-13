use Mix.Config

config :graphql, GraphQL.Endpoint,
  http: [port: 4001],
  server: false

config :logger, level: :info
config :ex_unit, capture_log: true

config :graphql, ecto_repos: [Core.Repo, Core.PRMRepo]
