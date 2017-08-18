defmodule EHealth.PRMFactories.EmployeeFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def employee_factory do
        division = build(:division)
        party = build(:party)

        %EHealth.PRM.Employees.Schema{
          is_active: true,
          position: "some position",
          status: "APPROVED",
          employee_type: "DOCTOR",
          end_date: ~D[2012-04-17],
          start_date: ~D[2017-03-22],
          party: party,
          division: division,
          legal_entity_id: division.legal_entity.id,
          inserted_by: UUID.generate(),
          updated_by: UUID.generate()
        }
      end
    end
  end
end
