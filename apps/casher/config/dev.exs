use Mix.Config

config :casher, Casher.Redis,
  host: "127.0.0.1",
  database: 1,
  password: nil,
  port: 6379,
  pool_size: 5
