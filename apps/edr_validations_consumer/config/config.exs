use Mix.Config

config :edr_validations_consumer,
  kaffe_consumer: [
    endpoints: [localhost: 9092],
    topics: ["edr_verification_events"],
    consumer_group: "edr_verification_group",
    message_handler: EdrValidationsConsumer.Kafka.Consumer
  ]

config :edr_validations_consumer,
  topologies: [
    k8s_edr_api: [
      strategy: Elixir.Cluster.Strategy.Kubernetes,
      config: [
        mode: :dns,
        kubernetes_node_basename: "edr_api",
        kubernetes_selector: "app=edr-api",
        kubernetes_namespace: "edr",
        polling_interval: 10_000
      ]
    ],
    k8s_uaddresses: [
      strategy: Elixir.Cluster.Strategy.Kubernetes,
      config: [
        mode: :dns,
        kubernetes_node_basename: "uaddresses_api",
        kubernetes_selector: "app=api",
        kubernetes_namespace: "uaddresses",
        polling_interval: 10_000
      ]
    ]
  ]

import_config "#{Mix.env()}.exs"
