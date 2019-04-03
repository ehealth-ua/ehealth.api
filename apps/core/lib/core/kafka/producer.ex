defmodule Core.Kafka.Producer do
  @moduledoc false

  @deactivate_declaration_events_topic "deactivate_declaration_events"
  @edr_verification_events_topic "edr_verification_events"
  @event_manager_topic "event_manager_topic"

  @behaviour Core.Kafka.ProducerBehaviour

  require Logger

  def publish_to_event_manager(event), do: produce(@event_manager_topic, event)

  def publish_deactivate_declaration_event(event), do: produce(@deactivate_declaration_events_topic, event)

  def publish_verify_legal_entity(event), do: produce(@edr_verification_events_topic, event)

  defp produce(topic, event) do
    case Kaffe.Producer.produce_sync(topic, 0, "", :erlang.term_to_binary(event)) do
      :ok ->
        :ok

      error ->
        Logger.warn("Publish event #{inspect(event)} to #{topic} failed: #{inspect(error)}")
        error
    end
  end
end
