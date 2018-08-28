use Mix.Config

config :casher, Casher.Web.Endpoint,
  http: [port: 4001],
  server: false

config :casher, Redix, "redis://localhost:6379/1"
