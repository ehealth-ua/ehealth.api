defmodule Core.MPIFactories.PersonFactory do
  @moduledoc false

  alias Ecto.UUID

  defmacro __using__(_opts) do
    quote do
      def person_factory do
        %{
          version: "0.1",
          id: UUID.generate(),
          first_name: random_first_name(),
          last_name: random_last_name(),
          second_name: random_second_name(),
          email: "test@email.com",
          gender: Enum.random(["MALE", "FEMALE"]),
          birth_date: "1996-12-12",
          unzr: "19961212-00000",
          tax_id: sequence(:tax_id, &"tax_id-#{&1}"),
          invalid_tax_id: false,
          birth_country: random_bith_country(),
          birth_settlement: sequence(:birth_settlement, &"birth_settlement-#{&1}"),
          death_date: "2117-11-09",
          preferred_way_communication: "email",
          emergency_contact: %{},
          documents: [],
          addresses: [],
          phones: [],
          authentication_methods: [%{"type" => "OTP", "phone_number" => "+380955947998"}],
          merged_ids: [],
          secret: "secret-1",
          status: "active",
          is_active: true,
          patient_signed: true,
          process_disclosure_data_consent: true,
          inserted_by: UUID.generate(),
          updated_by: UUID.generate(),
          inserted_at: "2017-12-12",
          updated_at: "2017-12-12"
        }
      end

      def random_first_name, do: Enum.random(~w(Андрій Богда Василь Ганна Дмитро Катерина Людмила Марина Назар Петро))

      def random_second_name,
        do: Enum.random(~w(Андрійович Богданівна Вікторович Григориївна Михайлович Назаровна Остапович))

      def random_last_name, do: Enum.random(~w(Андрійченко Богданов Василенко Дмитренко Шевченко Стодоля Стародубна))

      def random_bith_country,
        do: Enum.random(~w(Україна Польша Румунія Італія Португалія Іспанія Франція Великобританія США Японія))
    end
  end
end
