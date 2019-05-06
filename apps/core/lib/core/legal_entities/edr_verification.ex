defmodule Core.LegalEntities.EdrVerification do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID

  @status_verified "VERIFIED"
  @status_error "VERIFICATION_ERROR"

  def status(:verified), do: @status_verified
  def status(:error), do: @status_error

  @fields_required ~w(legal_entity_id)a

  @fields_optional ~w(
    status_code
    edr_status
    edr_data
    legal_entity_data
    edr_state
    error_message
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "edr_verifications" do
    field(:status_code, :integer)
    field(:edr_status, :string)
    field(:edr_data, :map)
    field(:legal_entity_data, :map)
    field(:edr_state, :integer)
    field(:error_message, :string)
    field(:legal_entity_id, UUID)

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  def changeset(edr_verification, params) do
    edr_verification
    |> cast(params, @fields_required ++ @fields_optional)
    |> validate_required(@fields_required)
  end
end
