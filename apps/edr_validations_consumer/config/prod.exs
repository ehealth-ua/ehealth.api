use Mix.Config

config :edr_validations_consumer,
  kaffe_consumer: [
    endpoints: {:system, :string, "KAFKA_BROKERS"},
    topics: ["edr_verification_events"],
    consumer_group: "edr_verification_group",
    message_handler: EdrValidationsConsumer.Kafka.Consumer
  ]
