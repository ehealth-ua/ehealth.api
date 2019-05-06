defmodule Core.Services.ServicesGroups do
  @moduledoc false

  use Ecto.Schema

  alias Core.Services.Service
  alias Core.Services.ServiceGroup
  alias Ecto.UUID

  @primary_key false
  schema "services_groups" do
    field(:alias, :string)
    field(:inserted_by, UUID)
    field(:updated_by, UUID)

    belongs_to(:service, Service, type: UUID, primary_key: true)
    belongs_to(:service_group, ServiceGroup, type: UUID, primary_key: true)

    timestamps(type: :utc_datetime_usec)
  end
end
