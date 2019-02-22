defmodule Core.Kafka.ProducerBehaviour do
  @moduledoc false

  @callback publish_deactivate_declaration_event(event :: map) :: :ok | {:error, reason :: term}
end
