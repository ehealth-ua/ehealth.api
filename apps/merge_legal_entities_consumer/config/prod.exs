use Mix.Config

config :merge_legal_entities_consumer,
  kaffe_consumer: [
    endpoints: {:system, :string, "KAFKA_BROKERS"},
    topics: ["merge_legal_entities"],
    consumer_group: "merge_legal_entities_group",
    message_handler: Jobs.LegalEntityMergeJob
  ]
