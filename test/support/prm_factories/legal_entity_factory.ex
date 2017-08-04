defmodule EHealth.PRMFactories.LegalEntityFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def legal_entity_factory do
        %EHealth.PRM.LegalEntities.Schema{
          is_active: true,
          addresses: [],
          edrpou: "3378113538",
          email: "some email",
          kveds: [],
          legal_form: "240",
          name: "some name",
          owner_property_type: "STATE",
          phones: [],
          public_name: "some public_name",
          short_name: "some short_name",
          status: "ACTIVE",
          mis_verified: "VERIFIED",
          type: "MSP",
          nhs_verified: false,
          updated_by: UUID.generate(),
          inserted_by: UUID.generate(),
          created_by_mis_client_id: UUID.generate()
        }
      end
    end
  end
end
