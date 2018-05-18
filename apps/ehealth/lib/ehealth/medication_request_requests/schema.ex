defmodule EHealth.MedicationRequestRequest do
  @moduledoc """
    Medication request Request is a life-cycle entity that is used to perform operations on Medication requests.
    After Medication request Request is signed it will be automatically moved to Medication requests.
  """
  use Ecto.Schema
  alias EHealth.MedicationRequestRequest.EmbeddedData

  @derive {Jason.Encoder, except: [:__meta__]}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "medication_request_requests" do
    embeds_one(:data, EmbeddedData)
    field(:request_number, :string, null: false)
    field(:verification_code, :string, null: true)
    field(:inserted_by, Ecto.UUID, null: false)
    field(:status, :string, null: false)
    field(:updated_by, Ecto.UUID, null: false)
    field(:medication_request_id, Ecto.UUID, null: false)

    timestamps(type: :utc_datetime)
  end

  @status_new "NEW"
  @status_signed "SIGNED"
  @status_expired "EXPIRED"
  @status_rejected "REJECTED"

  def status(:new), do: @status_new
  def status(:signed), do: @status_signed
  def status(:expired), do: @status_expired
  def status(:rejected), do: @status_rejected
end

defmodule EHealth.MedicationRequestRequest.EmbeddedData do
  @moduledoc false
  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:created_at, :date, null: false)
    field(:started_at, :date, null: false)
    field(:ended_at, :date, null: false)
    field(:dispense_valid_from, :date, null: false)
    field(:dispense_valid_to, :date, null: false)
    field(:person_id, Ecto.UUID, null: false)
    field(:employee_id, Ecto.UUID, null: false)
    field(:division_id, Ecto.UUID, null: false)
    field(:medication_id, Ecto.UUID, null: false)
    field(:legal_entity_id, Ecto.UUID, null: false)
    field(:medication_qty, :integer, null: false)
    field(:medical_program_id, Ecto.UUID, null: false)
  end
end
