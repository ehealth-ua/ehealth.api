use Mix.Config

config :graphql, GraphQLWeb.Endpoint,
  http: [port: 4000],
  debug_errors: true,
  check_origin: false

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20
