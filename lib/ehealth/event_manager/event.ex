defmodule EHealth.EventManager.Event do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "events" do
    field :event_type, :string
    field :entity_type, :string
    field :entity_id, Ecto.UUID
    field :properties, :map
    field :event_time, :naive_datetime
    field :changed_by, Ecto.UUID

    timestamps()
  end
end
