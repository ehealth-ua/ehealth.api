defmodule GraphQLWeb.Schema.MedicationTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  input_object :medication_filter do
    field(:database_id, :uuid)
    field(:name, :string)
    field(:is_active, :boolean)
    field(:form, :string)
    field(:innm_dosage, :innm_dosage_filter)
    field(:manufacturer, :manufacturer_filter)
  end

  input_object :manufacturer_filter do
    field(:name, :string)
  end

  enum :medication_order_by do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:name_asc)
    value(:name_desc)
  end

  node object(:medication) do
    field(:database_id, non_null(:uuid))
    field(:name, non_null(:string))
    field(:manufacturer, :manufacturer)
    field(:code_atc, non_null(list_of(:code_atc)))
    field(:form, :medication_form)
    field(:container, non_null(:container))
    field(:package_qty, :string)
    field(:package_min_qty, :string)
    field(:certificate, :string)
    field(:certificate_expired_at, :date)
    field(:ingredients, non_null(list_of(:medication_ingredient)))
    field(:is_active, non_null(:boolean))
    field(:type, :medication_type)
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end

  object :manufacturer do
    field(:name, non_null(:string))
    field(:country, non_null(:string))
  end

  enum :medication_form do
    value(:aerosol_for_inhalation, as: "AEROSOL_FOR_INHALATION")
    value(:aerosol_for_inhalation_dosed, as: "AEROSOL_FOR_INHALATION_DOSED")
    value(:coated_tablet, as: "COATED_TABLET")
    value(:film_coated_tablet, as: "FILM_COATED_TABLET")
    value(:inhalation_powder, as: "INHALATION_POWDER")
    value(:modifiedrelease_tablet, as: "MODIFIEDRELEASE_TABLET")
    value(:nebuliser_suspension, as: "NEBULISER_SUSPENSION")
    value(:pressurised_inhalation, as: "PRESSURISED_INHALATION")
    value(:sublingval_tablet, as: "SUBLINGVAL_TABLET")
    value(:tablet, as: "TABLET")
  end

  object :code_atc do
    field(:code_atc, non_null(:string))
  end

  object :container do
    field(:numerator_unit, non_null(:medication_unit))
    field(:numerator_value, non_null(:string))
    field(:denumerator_unit, non_null(:medication_unit))
    field(:denumerator_value, non_null(:string))
  end

  object :medication_ingredient do
    interface(:ingredient)

    field(:dosage, non_null(:dosage))
    field(:is_primary, non_null(:boolean))
    field(:innm_dosage, non_null(:innm_dosage))
  end

  enum :medication_type do
    value(:brand, as: "BRAND")
    value(:innm_dosage, as: "INNM_DOSAGE")
  end
end
