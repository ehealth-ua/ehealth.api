use Mix.Config

# Print only warnings and errors during test
config :logger, level: :warn

config :taskafka, :mongo, url: "mongodb://localhost:27017/taskafka_test"
config :taskafka, :idle, true
