use Mix.Config

config :graphql, GraphQLWeb.Endpoint,
  http: [port: 4001],
  server: false

config :taskafka, :mongo, url: "mongodb://localhost:27017/taskafka_test"
config :taskafka, :idle, true

config :logger, level: :info
config :ex_unit, capture_log: true

config :graphql, ecto_repos: [Core.Repo, Core.PRMRepo]
