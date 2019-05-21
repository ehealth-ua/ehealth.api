defmodule Core.Kafka.ProducerBehaviour do
  @moduledoc false

  @callback publish_deactivate_declaration_event(event :: map) :: :ok | {:error, reason :: term}

  @callback publish_sync_edr_data(event :: map) :: :ok | {:error, reason :: term}

  @callback publish_to_event_manager(event :: map) ::
              :ok
              | {:ok, integer}
              | {:error, :closed}
              | {:error, :inet.posix()}
              | {:error, any}
              | iodata
              | :leader_not_available
end
