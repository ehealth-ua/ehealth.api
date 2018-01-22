defmodule EHealth.PRMFactories.LegalEntityFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def legal_entity_factory do
        %EHealth.LegalEntities.LegalEntity{
          is_active: true,
          addresses: [],
          edrpou: to_string(3_300_000_000 + :rand.uniform(99_999_999)),
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
          website: "http://example.com",
          archive: [%{"date" => "2012-12-29", "place" => "Житомир вул. Малярів, буд. 211, корп. 2, оф. 1"}],
          beneficiary: "Марко Вовчок",
          receiver_funds_code: "088912",
          updated_by: UUID.generate(),
          inserted_by: UUID.generate(),
          created_by_mis_client_id: UUID.generate(),
          medical_service_provider: build(:medical_service_provider)
        }
      end
    end
  end
end
