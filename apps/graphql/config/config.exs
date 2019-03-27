use Mix.Config

# General application configuration
config :graphql,
  env: Mix.env(),
  namespace: GraphQL

# Configures the endpoint
config :graphql, GraphQL.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "CYmgC8ImSRDRzR8UuogkPi3LY9xnvdta6S4pJmKDSQPnqRF9p5PNNS11eE7a2Uc5",
  debug_errors: false,
  render_errors: [
    view: GraphQL.Resolvers.Helpers.ErrorView,
    accepts: ~w(json)
  ],
  instrumenters: [LoggerJSON.Phoenix.Instruments]

# Config Jason as default Json encoder for Phoenix
config :phoenix, :format_encoders, json: Jason

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
    ],
    k8s_manual_merger: [
      strategy: Elixir.Cluster.Strategy.Kubernetes,
      config: [
        mode: :dns,
        kubernetes_node_basename: "manual_merger",
        kubernetes_selector: "app=manual-merger",
        kubernetes_namespace: "mpi",
        polling_interval: 10_000
      ]
    ]
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
