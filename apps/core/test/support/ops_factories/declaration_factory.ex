defmodule Core.OPSFactories.DeclarationFactory do
  @moduledoc false

  use Timex
  alias Ecto.UUID

  defmacro __using__(_opts) do
    quote do
      def declaration_factory do
        now = DateTime.utc_now()
        start_date = Timex.shift(now, days: -10) |> Timex.to_date()
        signed_at = Timex.to_datetime(start_date)
        end_date = Timex.shift(start_date, days: 1)

        %{
          id: UUID.generate(),
          declaration_request_id: UUID.generate(),
          start_date: start_date,
          end_date: end_date,
          status: "active",
          signed_at: signed_at,
          created_by: UUID.generate(),
          updated_by: UUID.generate(),
          employee_id: UUID.generate(),
          person_id: UUID.generate(),
          division_id: UUID.generate(),
          legal_entity_id: UUID.generate(),
          is_active: true,
          scope: "",
          declaration_number: sequence(:declaration_number, &"test-declaration-number-#{&1}"),
          reason: "",
          reason_description: "",
          inserted_at: now,
          updated_at: now
        }
      end
    end
  end
end
