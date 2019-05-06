defmodule Core.Medications.Medication do
  @moduledoc false

  use Ecto.Schema

  alias Core.Medications.Medication.Ingredient

  @medication_type "BRAND"

  @derive {Jason.Encoder, except: [:__meta__, :ingredients, :innm_dosages]}

  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts type: :utc_datetime_usec
  schema "medications" do
    field(:name, :string)
    field(:form, :string)
    field(:type, :string)
    field(:code_atc, {:array, :string})
    field(:certificate, :string)
    field(:certificate_expired_at, :date)
    field(:container, :map)
    field(:manufacturer, :map)
    field(:package_qty, :integer)
    field(:package_min_qty, :integer)
    field(:is_active, :boolean, default: true)
    field(:daily_dosage, :float)
    field(:inserted_by, Ecto.UUID)
    field(:updated_by, Ecto.UUID)

    has_many(:ingredients, Ingredient, foreign_key: :parent_id)
    has_many(:innm_dosages, through: [:ingredients, :innm_dosage])

    timestamps(type: :utc_datetime_usec)
  end

  def type, do: @medication_type
end
