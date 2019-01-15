use Mix.Config

# Do not print debug messages in production
config :logger, level: :info

config :taskafka, :mongo, url: "${MONGO_DB_URL}"
