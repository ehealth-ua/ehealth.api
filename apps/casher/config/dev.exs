use Mix.Config

config :casher, Casher.Web.Endpoint,
  http: [port: {:system, "PORT", 4000}],
  debug_errors: false,
  code_reloader: true,
  check_origin: false,
  watchers: []

config :phoenix, :stacktrace_depth, 20

config :casher, Casher.Redis,
  host: "127.0.0.1",
  database: 1,
  password: nil,
  port: 6379,
  pool_size: 5
