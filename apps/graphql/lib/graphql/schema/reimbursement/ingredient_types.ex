defmodule GraphQL.Schema.IngredientTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  interface :ingredient do
    field(:dosage, non_null(:dosage))
    field(:is_primary, non_null(:boolean))

    resolve_type(fn
      %{innm_dosage: _}, _ -> :medication_ingredient
      %{innm: _}, _ -> :innm_dosage_ingredient
      _, _ -> nil
    end)
  end

  object :dosage do
    field(:numerator_unit, non_null(:medication_unit))
    field(:numerator_value, non_null(:string))
    field(:denumerator_unit, non_null(:medication_unit))
    field(:denumerator_value, non_null(:string))
  end

  # ToDo: remove or get values from dictionaries
  enum :medication_unit do
    value(:aerosol, as: "AEROSOL")
    value(:ampoule, as: "AMPOULE")
    value(:bottle, as: "BOTTLE")
    value(:container, as: "CONTAINER")
    value(:dose, as: "DOSE")
    value(:ie, as: "IE")
    value(:mg, as: "MG")
    value(:mkg, as: "MKG")
    value(:ml, as: "ML")
    value(:pill, as: "PILL")
    value(:vial, as: "VIAL")
  end
end
