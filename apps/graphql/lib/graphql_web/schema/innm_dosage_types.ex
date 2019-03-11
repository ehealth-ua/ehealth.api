defmodule GraphQLWeb.Schema.INNMDosageTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  input_object :innm_dosage_filter do
    field(:database_id, :uuid)
    field(:name, :string)
  end

  enum :innm_dosage_order_by do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
  end

  node object(:innm_dosage) do
    field(:database_id, non_null(:uuid))
    field(:name, non_null(:string))
    field(:form, non_null(:medication_form))
    field(:ingredients, non_null(list_of(:innm_dosage_ingredient)))
    field(:is_active, non_null(:boolean))

    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end

  object(:innm_dosage_ingredient) do
    interface(:ingredient)

    field(:dosage, non_null(:dosage))
    field(:is_primary, non_null(:boolean))
    field(:innm, non_null(:innm))
  end
end
