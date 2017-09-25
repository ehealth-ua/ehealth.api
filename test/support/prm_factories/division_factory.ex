defmodule EHealth.PRMFactories.DivisionFactory do
  @moduledoc false

  alias EHealth.PRM.Divisions.Schema, as: Division

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def division_factory do
        %EHealth.PRM.Divisions.Schema{
          legal_entity: build(:legal_entity),
          addresses: [],
          phones: [],
          external_id: "7ae4bbd6-a9e7-4ce0-992b-6a1b18a262dc",
          type: Division.type(:clinic),
          email: "some",
          name: "some",
          status: Division.status(:active),
          mountain_group: false,
        }
      end
    end
  end
end
