use Mix.Config

config :casher, Casher.Web.Endpoint,
  http: [port: {:system, "PORT", 4000}],
  debug_errors: false,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :phoenix, :stacktrace_depth, 20

config :casher, Redix,
  host: "127.0.0.1",
  port: 6379
