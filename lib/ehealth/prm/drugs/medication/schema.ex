defmodule EHealth.PRM.Drugs.Medication.Schema do
  @moduledoc false
  use Ecto.Schema

  @medication_type "MEDICATION"

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

    has_many :ingredients, EHealth.PRM.Drugs.Medication.Ingredient, [on_replace: :delete, foreign_key: :medication_id]

    timestamps()
  end

  def type, do: @medication_type
end
