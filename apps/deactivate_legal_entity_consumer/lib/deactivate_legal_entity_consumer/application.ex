defmodule DeactivateLegalEntityConsumer.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Jobs.LegalEntityDeactivationJob

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    topic_names = ~w(deactivate_legal_entity_event)
    consumer_group_name = "deactivate_legal_entity_event_group"

    consumer_group_opts = [
      heartbeat_interval: 1_000,
      commit_interval: 1_000
    ]

    children = [
      supervisor(KafkaEx.ConsumerGroup, [
        LegalEntityDeactivationJob,
        consumer_group_name,
        topic_names,
        consumer_group_opts
      ])
    ]

    opts = [strategy: :one_for_one, name: DeactivateLegalEntityConsumer.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
