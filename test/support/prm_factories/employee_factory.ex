defmodule EHealth.PRMFactories.EmployeeFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def employee_factory do
        legal_entity = build(:legal_entity)

        %EHealth.PRM.Employees.Schema{
          is_active: true,
          position: "some position",
          status: "some status",
          employee_type: "some type",
          end_date: ~D[2012-04-17],
          start_date: ~D[2017-03-22],
          party: build(:party),
          division: build(:division, legal_entity: legal_entity),
          legal_entity: legal_entity,
          inserted_by: UUID.generate(),
          updated_by: UUID.generate()
        }
      end
    end
  end
end
