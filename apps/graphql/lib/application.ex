defmodule GraphQL.Application do
  @moduledoc """
  This application provides GraphQL API for eHealth services.
  """

  use Application

  alias Core.Jobs.LegalEntityMergeJob

  def start(_type, _args) do
    import Supervisor.Spec

    topic_names = ~w(merge_legal_entities)
    consumer_group_name = "merge_legal_entities_group"

    consumer_group_opts = [
      # setting for the ConsumerGroup
      heartbeat_interval: 1_000,
      # this setting will be forwarded to the GenConsumer
      commit_interval: 1_000
    ]

    children = [
      supervisor(GraphQLWeb.Endpoint, []),
      supervisor(KafkaEx.ConsumerGroup, [LegalEntityMergeJob, consumer_group_name, topic_names, consumer_group_opts])
    ]

    opts = [strategy: :one_for_one, name: GraphQL.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def config_change(changed, _new, removed) do
    GraphQLWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
