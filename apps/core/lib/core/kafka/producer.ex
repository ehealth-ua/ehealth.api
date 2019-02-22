defmodule Core.Kafka.Producer do
  @moduledoc false

  @deactivate_declaration_events_topic "deactivate_declaration_events"
  @behaviour Core.Kafka.ProducerBehaviour

  require Logger

  def publish_deactivate_declaration_event(event) do
    with :ok <-
           Kaffe.Producer.produce_sync(@deactivate_declaration_events_topic, 0, nil, :erlang.term_to_binary(event)) do
      Logger.info("Published event #{inspect(event)} to kafka", application: :kaffe)
      :ok
    end
  end
end
