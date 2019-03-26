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
    # Dictionary: MEDICATION_UNIT
    field(:numerator_unit, non_null(:string))
    field(:numerator_value, non_null(:string))
    # Dictionary: MEDICATION_UNIT
    field(:denumerator_unit, non_null(:string))
    field(:denumerator_value, non_null(:string))
  end
end
