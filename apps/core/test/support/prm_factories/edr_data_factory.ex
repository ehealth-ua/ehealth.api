defmodule Core.PRMFactories.EdrDataFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Core.LegalEntities.EdrData
      alias Ecto.UUID

      def edr_data_factory do
        %EdrData{
          id: UUID.generate(),
          edr_id: DateTime.to_unix(DateTime.utc_now()),
          name: "foo",
          public_name: "foo",
          state: 1,
          is_active: true,
          legal_entities: [build(:legal_entity, nhs_verified: true)],
          edrpou: to_string(3_300_000_000 + :rand.uniform(99_999_999)),
          kveds: [],
          registration_address: %{},
          inserted_by: UUID.generate(),
          updated_by: UUID.generate()
        }
      end
    end
  end
end
