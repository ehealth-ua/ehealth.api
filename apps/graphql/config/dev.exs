use Mix.Config

config :graphql, GraphQLWeb.Endpoint,
  http: [port: 4000],
  check_origin: false,
  load_from_system_env: true,
  code_reloader: true

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20
