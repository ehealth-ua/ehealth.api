use Mix.Config

# General application configuration
config :graphql,
  env: Mix.env(),
  namespace: GraphQL

# Configures the endpoint
config :graphql, GraphQLWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "CYmgC8ImSRDRzR8UuogkPi3LY9xnvdta6S4pJmKDSQPnqRF9p5PNNS11eE7a2Uc5",
  debug_errors: false,
  render_errors: [
    view: GraphQLWeb.Resolvers.Helpers.ErrorView,
    accepts: ~w(json)
  ]

# Config Jason as default Json encoder for Phoenix
config :phoenix, :format_encoders, json: Jason

config :core, GraphQL.Jobs.LegalEntityMergeJob,
  client_type_id: {:system, "CLIENT_TYPE_MSP_LIMITED_ID"},
  media_storage_resource_name: {:system, "MEDIA_STORAGE_MERGED_LEGAL_ENTITIES_RESOURCE_NAME", "merged_legal_entities"}

config :kafka_ex,
  brokers: "localhost:9092",
  consumer_group: "ehealth",
  disable_default_worker: false,
  sync_timeout: 3000,
  max_restarts: 10,
  max_seconds: 60,
  commit_interval: 5_000,
  auto_offset_reset: :earliest,
  commit_threshold: 100,
  kafka_version: "1.1.0"

config :graphql,
  topologies: [
    k8s_ops: [
      strategy: Elixir.Cluster.Strategy.Kubernetes,
      config: [
        mode: :dns,
        kubernetes_node_basename: "ops",
        kubernetes_selector: "app=api",
        kubernetes_namespace: "ops",
        polling_interval: 10_000
      ]
    ],
    k8s_mpi: [
      strategy: Elixir.Cluster.Strategy.Kubernetes,
      config: [
        mode: :dns,
        kubernetes_node_basename: "mpi",
        kubernetes_selector: "app=api",
        kubernetes_namespace: "mpi",
        polling_interval: 10_000
      ]
    ]
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
