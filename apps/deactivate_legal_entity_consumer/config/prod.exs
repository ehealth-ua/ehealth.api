use Mix.Config

config :deactivate_legal_entity_consumer,
  kaffe_consumer: [
    endpoints: {:system, :string, "KAFKA_BROKERS"},
    topics: ["deactivate_legal_entity_event"],
    consumer_group: "deactivate_legal_entity_event_group",
    message_handler: Jobs.LegalEntityDeactivationJob
  ]
