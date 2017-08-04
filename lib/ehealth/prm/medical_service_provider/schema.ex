defmodule EHealth.PRM.MedicalServiceProviders.Schema do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "medical_service_providers" do
    field :accreditation, :map
    field :licenses, {:array, :map}

    belongs_to :legal_entity, EHealth.PRM.LegalEntities.Schema, type: Ecto.UUID

    timestamps()
  end
end
