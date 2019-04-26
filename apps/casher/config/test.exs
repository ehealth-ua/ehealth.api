use Mix.Config

config :casher, Redix, "redis://localhost:6379/1"

config :casher, Casher.Redis,
  host: "127.0.0.1",
  database: 0,
  password: nil,
  port: 6379,
  pool_size: 5
