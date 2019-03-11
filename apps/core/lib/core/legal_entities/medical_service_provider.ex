defmodule Core.LegalEntities.MedicalServiceProvider do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @derive {Jason.Encoder, except: [:__meta__, :legal_entity]}

  @optional_fields ~w(
    accreditation
    licenses
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "medical_service_providers" do
    field(:accreditation, :map)
    field(:licenses, {:array, :map})

    belongs_to(:legal_entity, Core.LegalEntities.LegalEntity, type: Ecto.UUID)

    timestamps(type: :utc_datetime)
  end

  def changeset(%__MODULE__{} = doc, attrs) do
    cast(doc, attrs, @optional_fields)
  end
end
