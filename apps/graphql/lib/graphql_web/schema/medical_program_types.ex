defmodule GraphQLWeb.Schema.MedicalProgramTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  input_object :medical_program_filter do
    field(:database_id, :id)
    field(:name, :string)
    field(:is_active, :boolean)
  end

  enum :medical_program_order_by do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
    value(:name_asc)
    value(:name_desc)
  end

  node object(:medical_program) do
    field(:database_id, non_null(:id))
    field(:name, non_null(:string))
    field(:is_active, non_null(:boolean))
    # TODO: Timestamp fields should return :datetime type
    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))
  end
end
