defmodule EHealth.OPSFactories.MedicationDispenseDetailsFactory do
  @moduledoc false
  alias Ecto.UUID

  defmacro __using__(_opts) do
    quote do
      def medication_dispense_details_factory do
        %{
          id: UUID.generate(),
          medication: nil,
          medication_id: UUID.generate(),
          medication_qty: 10,
          sell_price: 150,
          reimbursement_amount: 100,
          medication_dispense_id: UUID.generate(),
          sell_amount: 30,
          discount_amount: 0
        }
      end
    end
  end
end
