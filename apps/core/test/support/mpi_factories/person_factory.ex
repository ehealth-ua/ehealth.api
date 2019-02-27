defmodule Core.MPIFactories.PersonFactory do
  @moduledoc false

  alias Ecto.UUID

  defmacro __using__(_opts) do
    quote do
      def person_factory do
        id = UUID.generate()
        now = DateTime.utc_now()

        %{
          version: "0.1",
          id: id,
          first_name: random_first_name(),
          last_name: random_last_name(),
          second_name: random_second_name(),
          email: sequence(:email, &"test#{&1}@email.com"),
          gender: Enum.random(["MALE", "FEMALE"]),
          birth_date: ~D[1996-12-12],
          unzr: "19961212-00000",
          tax_id: sequence(:tax_id, &"tax_id-#{&1}"),
          no_tax_id: false,
          invalid_tax_id: false,
          birth_country: random_birth_country(),
          birth_settlement: sequence(:birth_settlement, &"birth_settlement-#{&1}"),
          death_date: ~D[2117-11-09],
          preferred_way_communication: "email",
          emergency_contact: build(:emergency_contact),
          documents: build_list(2, :person_document, person_id: id),
          addresses: build_list(1, :person_address, person_id: id),
          phones: [],
          authentication_methods: [%{"type" => "OTP", "phone_number" => random_phone_number()}],
          master_persons: [],
          merged_persons: [],
          secret: "secret-1",
          status: "active",
          is_active: true,
          patient_signed: true,
          process_disclosure_data_consent: true,
          inserted_by: UUID.generate(),
          updated_by: UUID.generate(),
          inserted_at: now,
          updated_at: now
        }
      end

      def person_document_factory do
        now = DateTime.utc_now()

        %{
          id: UUID.generate(),
          expiration_date: "2013-08-19",
          issued_at: "2013-08-19",
          issued_by: "1234",
          number: "АА120518",
          person_id: UUID.generate(),
          type: "PASSPORT",
          inserted_at: now,
          updated_at: now
        }
      end

      def person_address_factory do
        %{
          id: UUID.generate(),
          apartment: to_string(Enum.random(1..500)),
          area: "ЗАПОРІЗЬКА",
          building: to_string(Enum.random(1..500)),
          country: "UA",
          person_id: UUID.generate(),
          region: "ЯКИМІВСЬКИЙ",
          settlement: "СОЛОНЕ",
          settlement_id: UUID.generate(),
          settlement_type: "CITY",
          street: "Верховинна",
          street_type: "STREET",
          type: "REGISTRATION",
          zip: "02090",
          inserted_at: UUID.generate(),
          updated_at: UUID.generate()
        }
      end

      def person_phone_factory do
        now = DateTime.utc_now()

        %{
          id: UUID.generate(),
          number: random_phone_number(),
          person_id: UUID.generate(),
          type: "MOBILE",
          inserted_at: now,
          updated_at: now
        }
      end

      def emergency_contact_factory do
        %{
          "first_name" => random_first_name(),
          "last_name" => random_last_name(),
          "second_name" => random_second_name(),
          "phones" => build_list(1, :embedded_phone)
        }
      end

      def confidant_person_factory do
        %{
          "relation_type" => Enum.random(["PRIMARY", "SECONDARY"]),
          "first_name" => random_first_name(),
          "last_name" => random_last_name(),
          "second_name" => random_second_name(),
          "birth_date" => "1996-12-12",
          "birth_country" => random_birth_country(),
          "birth_settlement" => sequence(:birth_settlement, &"birth_settlement-#{&1}"),
          "gender" => Enum.random(["MALE", "FEMALE"]),
          "tax_id" => sequence(:tax_id, &"tax_id-#{&1}"),
          "secret" => "secret-1",
          "phones" => build_list(1, :embedded_phone),
          "documents_person" => build_list(2, :embedded_document),
          "documents_relationship" => build_list(2, :embedded_document)
        }
      end

      def embedded_document_factory do
        %{
          type: "PASSPORT",
          number: "АА120518",
          issued_at: "2013-08-19",
          issued_by: "1234"
        }
      end

      def embedded_phone_factory do
        %{
          type: "MOBILE",
          number: random_phone_number()
        }
      end

      def random_first_name, do: Enum.random(~w(Андрій Богда Василь Ганна Дмитро Катерина Людмила Марина Назар Петро))

      def random_second_name,
        do: Enum.random(~w(Андрійович Богданівна Вікторович Григориївна Михайлович Назаровна Остапович))

      def random_last_name, do: Enum.random(~w(Андрійченко Богданов Василенко Дмитренко Шевченко Стодоля Стародубна))

      def random_birth_country,
        do: Enum.random(~w(Україна Польща Румунія Італія Португалія Іспанія Франція Великобританія США Японія))

      def random_phone_number, do: "+38097#{Enum.random(1_000_000..9_999_999)}"
    end
  end
end
