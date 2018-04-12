defmodule EHealth.OPSFactories.MedicationRequestFactory do
  @moduledoc false

  alias Ecto.UUID

  defmacro __using__(_opts) do
    quote do
      def medication_request_factory do
        %{
          id: UUID.generate(),
          status: "ACTIVE",
          inserted_by: UUID.generate(),
          updated_by: UUID.generate(),
          is_active: true,
          person_id: UUID.generate(),
          employee_id: UUID.generate(),
          division_id: UUID.generate(),
          medication_id: UUID.generate(),
          created_at: NaiveDateTime.utc_now() |> NaiveDateTime.to_date(),
          started_at: NaiveDateTime.utc_now() |> NaiveDateTime.to_date(),
          ended_at: NaiveDateTime.utc_now() |> NaiveDateTime.to_date(),
          dispense_valid_from: Date.utc_today(),
          dispense_valid_to: Date.utc_today(),
          medical_program_id: UUID.generate(),
          medication_qty: 0,
          medication_request_requests_id: UUID.generate(),
          request_number: to_string(:rand.uniform()),
          legal_entity_id: UUID.generate(),
          inserted_at: NaiveDateTime.utc_now(),
          updated_at: NaiveDateTime.utc_now(),
          verification_code: "",
          rejected_at: nil,
          rejected_by: nil,
          reject_reason: ""
        }
      end
    end
  end
end
