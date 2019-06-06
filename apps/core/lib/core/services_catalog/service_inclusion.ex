defmodule Core.Services.ServiceInclusion do
  @moduledoc false

  use Ecto.Schema

  alias Core.Services.{Service, ServiceGroup}
  alias Ecto.UUID

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "service_inclusions" do
    field(:alias, :string)
    field(:is_active, :boolean)
    field(:inserted_by, UUID)
    field(:updated_by, UUID)

    belongs_to(:service, Service, type: UUID, primary_key: true)
    belongs_to(:service_group, ServiceGroup, type: UUID, primary_key: true)

    timestamps(type: :utc_datetime_usec)
  end
end
