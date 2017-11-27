defmodule EHealth.LegalEntities.MedicalServiceProvider do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @optional_fields ~w(
    accreditation
    licenses
  )a

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "medical_service_providers" do
    field :accreditation, :map
    field :licenses, {:array, :map}

    belongs_to :legal_entity, EHealth.LegalEntities.LegalEntity, type: Ecto.UUID

    timestamps()
  end

  def changeset(%__MODULE__{} = doc, attrs) do
    cast(doc, attrs, @optional_fields)
  end
end
