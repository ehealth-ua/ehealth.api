use Mix.Config

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "$message\n"

config :taskafka, :mongo, url: "mongodb://localhost:27017/taskafka_dev"
