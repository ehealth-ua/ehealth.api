defmodule Core.DLS.Registry do
  @moduledoc false

  use Ecto.Schema
  alias Core.Divisions.Division
  alias Ecto.UUID

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "dls_registry" do
    field(:dls_id, :string)
    field(:dls_status, :string)

    belongs_to(:division, Division, type: UUID)

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end
end
