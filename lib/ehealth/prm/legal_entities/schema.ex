defmodule EHealth.PRM.LegalEntities.Schema do
  @moduledoc false

  alias EHealth.PRM.MedicalServiceProviders.Schema, as: MedicalServiceProvider

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "legal_entities" do
    field :is_active, :boolean, default: false
    field :nhs_verified, :boolean, default: false
    field :addresses, {:array, :map}
    field :edrpou, :string
    field :email, :string
    field :kveds, {:array, :string}
    field :legal_form, :string
    field :name, :string
    field :owner_property_type, :string
    field :phones, {:array, :map}
    field :public_name, :string
    field :short_name, :string
    field :status, :string
    field :mis_verified, :string
    field :type, :string
    field :inserted_by, Ecto.UUID
    field :updated_by, Ecto.UUID
    field :capitation_contract_id, :id
    field :created_by_mis_client_id, Ecto.UUID

    has_one :medical_service_provider, MedicalServiceProvider, foreign_key: :legal_entity_id

    timestamps()
  end
end
