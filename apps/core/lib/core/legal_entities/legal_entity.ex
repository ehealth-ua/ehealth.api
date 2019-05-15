defmodule Core.LegalEntities.LegalEntity do
  @moduledoc false

  use Ecto.Schema

  alias Core.Divisions.Division
  alias Core.Employees.Employee
  alias Core.LegalEntities.MedicalServiceProvider
  alias Core.LegalEntities.RelatedLegalEntity

  @derive {Jason.Encoder, except: [:__meta__]}

  @status_active "ACTIVE"
  @status_closed "CLOSED"
  @status_reorganized "REORGANIZED"
  @status_suspended "SUSPENDED"

  @type_mis "MIS"
  @type_msp "MSP"
  @type_msp_pharmacy "MSP_PHARMACY"
  @type_nhs "NHS"
  @type_outpatient "OUTPATIENT"
  @type_pharmacy "PHARMACY"
  @type_primary_care "PRIMARY_CARE"

  @mis_verified_verified "VERIFIED"
  @mis_verified_not_verified "NOT_VERIFIED"

  def type(:mis), do: @type_mis
  def type(:msp), do: @type_msp
  def type(:msp_pharmacy), do: @type_msp_pharmacy
  def type(:nhs), do: @type_nhs
  def type(:outpatient), do: @type_outpatient
  def type(:pharmacy), do: @type_pharmacy
  def type(:primary_care), do: @type_primary_care

  def mis_verified(:verified), do: @mis_verified_verified
  def mis_verified(:not_verified), do: @mis_verified_not_verified

  def status(:active), do: @status_active
  def status(:closed), do: @status_closed
  def status(:reorganized), do: @status_reorganized
  def status(:suspended), do: @status_suspended

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "legal_entities" do
    field(:is_active, :boolean, default: false)
    field(:nhs_verified, :boolean, default: false)
    field(:nhs_reviewed, :boolean, default: false)
    field(:nhs_comment, :string, default: "")
    field(:addresses, {:array, :map})
    field(:edrpou, :string)
    field(:email, :string)
    field(:kveds, {:array, :string})
    field(:legal_form, :string)
    field(:name, :string)
    field(:owner_property_type, :string)
    field(:phones, {:array, :map})
    field(:archive, {:array, :map})
    field(:receiver_funds_code, :string)
    field(:website, :string)
    field(:beneficiary, :string)
    field(:public_name, :string)
    field(:short_name, :string)
    field(:status, :string)
    field(:status_reason, :string)
    field(:reason, :string)
    field(:mis_verified, :string)
    field(:type, :string)
    field(:inserted_by, Ecto.UUID)
    field(:updated_by, Ecto.UUID)
    field(:capitation_contract_id, :id)
    field(:created_by_mis_client_id, Ecto.UUID)
    field(:edr_verified, :boolean)

    has_one(:medical_service_provider, MedicalServiceProvider, on_replace: :delete, foreign_key: :legal_entity_id)
    has_one(:merged_to_legal_entity, RelatedLegalEntity, foreign_key: :merged_from_id)
    has_one(:employee, Employee, foreign_key: :legal_entity_id)
    has_many(:employees, Employee, foreign_key: :legal_entity_id)
    has_many(:divisions, Division, foreign_key: :legal_entity_id)
    has_many(:merged_from_legal_entities, RelatedLegalEntity, foreign_key: :merged_to_id)

    timestamps(type: :utc_datetime_usec)
  end
end
