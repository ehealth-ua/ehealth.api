defmodule EHealth.PRMFactories.DivisionFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def division_factory do
        %EHealth.PRM.Divisions.Schema{
          legal_entity: build(:legal_entity),
          addresses: [],
          phones: [],
          external_id: "7ae4bbd6-a9e7-4ce0-992b-6a1b18a262dc",
          type: "some",
          email: "some",
          name: "some",
          status: "some"
        }
      end
    end
  end
end
