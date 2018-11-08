defmodule MergeLegalEntitiesConsumer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias GraphQL.Jobs.LegalEntityMergeJob

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    topic_names = ~w(merge_legal_entities)
    consumer_group_name = "merge_legal_entities_group"

    consumer_group_opts = [
      heartbeat_interval: 1_000,
      commit_interval: 1_000
    ]

    children = [
      supervisor(KafkaEx.ConsumerGroup, [LegalEntityMergeJob, consumer_group_name, topic_names, consumer_group_opts])
    ]

    opts = [strategy: :one_for_one, name: MergeLegalEntitiesConsumer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
