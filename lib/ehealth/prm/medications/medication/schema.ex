defmodule EHealth.PRM.Medications.Medication.Schema do
  @moduledoc false
  use Ecto.Schema
  alias EHealth.PRM.Medications.Medication.Ingredient
  alias EHealth.PRM.Medications.Program.Schema, as: ProgramMedication

  @medication_type "BRAND"

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "medications" do
    field :name, :string
    field :form, :string
    field :type, :string
    field :code_atc, :string
    field :certificate, :string
    field :certificate_expired_at, :date
    field :container, :map
    field :manufacturer, :map
    field :package_qty, :integer
    field :package_min_qty, :integer
    field :is_active, :boolean, default: true
    field :inserted_by, Ecto.UUID
    field :updated_by, Ecto.UUID

    has_many :ingredients, Ingredient, foreign_key: :parent_id
    has_one :program_medication, ProgramMedication

    timestamps()
  end

  def type, do: @medication_type
end
