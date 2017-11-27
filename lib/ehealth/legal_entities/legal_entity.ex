defmodule EHealth.LegalEntities.LegalEntity do
  @moduledoc false

  alias EHealth.LegalEntities.MedicalServiceProvider

  use Ecto.Schema

  @status_active "ACTIVE"
  @status_closed "CLOSED"

  @type_msp "MSP"
  @type_mis "MIS"
  @type_pharmacy "PHARMACY"

  @mis_verified_verified "VERIFIED"
  @mis_verified_not_verified "NOT_VERIFIED"

  def type(:mis), do: @type_mis
  def type(:msp), do: @type_msp
  def type(:pharmacy), do: @type_pharmacy

  def mis_verified(:verified), do: @mis_verified_verified
  def mis_verified(:not_verified), do: @mis_verified_not_verified

  def status(:active), do: @status_active
  def status(:closed), do: @status_closed

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

    has_one :medical_service_provider, MedicalServiceProvider, [on_replace: :delete, foreign_key: :legal_entity_id]

    timestamps()
  end
end
