defmodule Core.Services.Service do
  @moduledoc false

  use Ecto.Schema

  alias Core.Services.{ProgramService, ServiceInclusion}
  alias Ecto.UUID

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "services" do
    field(:code, :string)
    field(:name, :string)
    field(:category, :string)
    field(:parent_id, UUID)
    field(:is_active, :boolean, default: true)
    field(:is_composition, :boolean)
    field(:request_allowed, :boolean)
    field(:inserted_by, UUID)
    field(:updated_by, UUID)

    has_many(:program_services, ProgramService)

    has_many(:group_inclusions, ServiceInclusion, where: [is_active: true])
    has_many(:service_groups, through: [:group_inclusions, :service_group])

    timestamps(type: :utc_datetime_usec)
  end
end
