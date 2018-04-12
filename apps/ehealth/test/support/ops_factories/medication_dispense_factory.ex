defmodule EHealth.OPSFactories.MedicationDispenseFactory do
  @moduledoc false

  alias Ecto.UUID

  defmacro __using__(_opts) do
    quote do
      def medication_dispense_factory do
        %{
          id: UUID.generate(),
          status: "NEW",
          inserted_by: UUID.generate(),
          updated_by: UUID.generate(),
          is_active: true,
          dispensed_at: to_string(Date.utc_today()),
          party_id: UUID.generate(),
          legal_entity_id: UUID.generate(),
          payment_id: UUID.generate(),
          division_id: UUID.generate(),
          medical_program_id: UUID.generate(),
          medication_request: nil,
          medication_request_id: UUID.generate(),
          inserted_at: NaiveDateTime.utc_now(),
          updated_at: NaiveDateTime.utc_now()
        }
      end
    end
  end
end
