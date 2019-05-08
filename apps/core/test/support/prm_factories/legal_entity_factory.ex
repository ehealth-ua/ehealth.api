defmodule Core.PRMFactories.LegalEntityFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Core.LegalEntities.LegalEntity
      alias Core.LegalEntities.RelatedLegalEntity
      alias Ecto.UUID

      def legal_entity_factory do
        %LegalEntity{
          is_active: true,
          addresses: [
            %{
              type: "REGISTRATION",
              country: "UA",
              area: "Житомирська",
              region: "Бердичівський",
              settlement: "Київ",
              settlement_type: "CITY",
              settlement_id: UUID.generate(),
              street_type: "STREET",
              street: "вул. Ніжинська",
              building: "15-В",
              apartment: "23",
              zip: "02090"
            }
          ],
          edrpou: to_string(3_300_000_000 + :rand.uniform(99_999_999)),
          email: "some email",
          kveds: [],
          legal_form: "240",
          name: "Клініка Борис",
          owner_property_type: "STATE",
          phones: [],
          public_name: "some public_name",
          short_name: "some short_name",
          status: "ACTIVE",
          mis_verified: "VERIFIED",
          type: "MSP",
          nhs_verified: false,
          nhs_reviewed: true,
          nhs_comment: "",
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

      def related_legal_entity_factory(attrs) do
        record = %RelatedLegalEntity{
          reason: "some reason",
          is_active: true,
          inserted_by: UUID.generate(),
          merged_from: build(:legal_entity),
          merged_to: build(:legal_entity)
        }

        record
        |> drop_overridden_fields(attrs)
        |> merge_attributes(attrs)
      end
    end
  end
end
