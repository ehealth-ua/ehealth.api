defmodule EHealth.MPIFactories.PersonFactory do
  @moduledoc false

  alias Ecto.UUID

  defmacro __using__(_opts) do
    quote do
      def person_factory do
        %{
          version: "0.1",
          id: UUID.generate(),
          first_name: randon_first_name(),
          last_name: randon_last_name(),
          second_name: sequence(:second_name, &"second_name-#{&1}"),
          email: "test@email.com",
          gender: Enum.random(["MALE", "FEMALE"]),
          national_id: sequence(:national_id, &"national_id-#{&1}"),
          tax_id: sequence(:tax_id, &"tax_id-#{&1}"),
          invalid_tax_id: false,
          birth_date: Date.to_string(~D[1996-12-12]),
          birth_country: sequence(:birth_country, &"birth_country-#{&1}"),
          birth_settlement: sequence(:birth_settlement, &"birth_settlement-#{&1}"),
          death_date: ~D[2117-11-09],
          preferred_way_communication: "email",
          emergency_contact: %{},
          documents: [],
          addresses: [],
          phones: [],
          authentication_methods: [],
          confidant_person: [],
          merged_ids: [],
          secret: "secret-1",
          status: "active",
          is_active: true,
          patient_signed: true,
          process_disclosure_data_consent: true,
          inserted_by: UUID.generate(),
          updated_by: UUID.generate(),
          inserted_at: ~D[2017-12-12],
          updated_at: ~D[2017-12-12]
        }
      end

      def randon_first_name, do: Enum.random(~w(Андрій Богда Василь Ганна Дмитро Катерина Людмила Марина Назар Петро))
      def randon_last_name, do: Enum.random(~w(Андрійченко Богданов Василенко Дмитренко Шевченко Стодоля Стародубна))
    end
  end
end
