defmodule GraphQLWeb.Schema.ProgramMedicationTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  input_object :program_medication_filter do
    field(:database_id, :uuid)
    field(:medical_program, :medical_program_filter)
    field(:is_active, :boolean)
    field(:medication_request_allowed, :boolean)
    field(:medication, :medication_filter)
  end

  enum :program_medication_order_by do
    value(:inserted_at_asc)
    value(:inserted_at_desc)
  end

  node object(:program_medication) do
    field(:database_id, non_null(:uuid))
    field(:medical_program, non_null(:medical_program))
    field(:medication, non_null(:medication))
    field(:reimbursement, non_null(:reimbursement))
    field(:wholesale_price, non_null(:string))
    field(:consumer_price, non_null(:string))
    field(:reimbursement_daily_dosage, non_null(:string))
    field(:estimated_payment_amount, non_null(:string))
    field(:is_active, non_null(:boolean))
    field(:medication_request_allowed, non_null(:boolean))

    # TODO: Timestamp fields should return :datetime type
    field(:inserted_at, non_null(:naive_datetime))
    field(:updated_at, non_null(:naive_datetime))
  end

  object :reimbursement do
    field(:type, non_null(:reimbursement_type))
    field(:reimbursement_amount, non_null(:string))
  end

  enum :reimbursement_type do
    value(:external, as: "EXTERNAL")
    value(:fixed, as: "FIXED")
  end
end
