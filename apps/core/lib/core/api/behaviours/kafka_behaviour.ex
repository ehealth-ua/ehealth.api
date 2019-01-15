defmodule Core.Kafka.ProducerBehaviour do
  @moduledoc false

  @callback publish_deactivate_declaration_event(event :: map) ::
              :ok
              | {:ok, integer}
              | {:error, :closed}
              | {:error, :inet.posix()}
              | {:error, any}
              | iodata
              | :leader_not_available
end
