defmodule GraphQLWeb.Schema.IngredientTypes do
  @moduledoc false

  use Absinthe.Schema.Notation

  interface :ingredient do
    field(:dosage, non_null(:dosage))
    field(:is_primary, non_null(:boolean))
  end

  object :dosage do
    field(:numerator_unit, non_null(:medication_unit))
    field(:numerator_value, non_null(:string))
    field(:denumerator_unit, non_null(:medication_unit))
    field(:denumerator_value, non_null(:string))
  end

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
