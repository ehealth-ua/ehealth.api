defmodule GraphQLWeb.Schema.ProgramMedicationTypes do
  @moduledoc false

  use Absinthe.Schema.Notation
  use Absinthe.Relay.Schema.Notation, :modern

  alias Absinthe.Relay.Node.ParseIDs
  alias GraphQLWeb.Resolvers.ProgramMedicationsResolver

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

  connection node_type: :program_medication do
    field :nodes, list_of(:program_medication) do
      resolve(fn
        _, %{source: conn} ->
          nodes = conn.edges |> Enum.map(& &1.node)
          {:ok, nodes}
      end)
    end

    edge(do: nil)
  end

  object :program_medication_mutations do
    payload field(:create_program_medication) do
      meta(:scope, ~w(program_medication:write))
      meta(:client_metadata, ~w(consumer_id)a)

      input do
        field(:medication_id, non_null(:id))
        field(:medical_program_id, non_null(:id))
        field(:reimbursement, non_null(:reimbursement))
        field(:wholesale_price, non_null(:float))
        field(:consumer_price, non_null(:float))
        field(:reimbursement_daily_dosage, non_null(:float))
        field(:estimated_payment_amount, non_null(:float))
      end

      output do
        field(:program_medication, :program_medication)
      end

      middleware(ParseIDs, medication_id: :medication, medical_program_id: :medical_program)
      resolve(&ProgramMedicationsResolver.create_program_medication/2)
    end
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
    field(:inserted_at, non_null(:datetime))
    field(:updated_at, non_null(:datetime))
  end

  object :reimbursement do
    field(:type, non_null(:reimbursement_type))
    field(:reimbursement_amount, non_null(:float))
  end

  enum :reimbursement_type do
    value(:external, as: "EXTERNAL")
    value(:fixed, as: "FIXED")
  end
end
