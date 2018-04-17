defmodule EHealth.MPIFactories.PersonFactory do
  @moduledoc false

  alias Ecto.UUID

  defmacro __using__(_opts) do
    quote do
      def person_factory do
        %{
          version: "0.1",
          id: UUID.generate(),
          first_name: sequence(:first_name, &"first_name-#{&1}"),
          last_name: sequence(:last_name, &"last_name-#{&1}"),
          second_name: sequence(:second_name, &"second_name-#{&1}"),
          birth_date: ~D[1996-12-12],
          birth_country: sequence(:birth_country, &"birth_country-#{&1}"),
          birth_settlement: sequence(:birth_settlement, &"birth_settlement-#{&1}"),
          gender: Enum.random(["MALE", "FEMALE"]),
          email: "test@email.com",
          tax_id: sequence(:tax_id, &"tax_id-#{&1}"),
          national_id: sequence(:national_id, &"national_id-#{&1}"),
          death_date: ~D[2117-11-09],
          preferred_way_communication: "email",
          is_active: true,
          documents: [],
          addresses: [],
          phones: [],
          secret: "secret-1",
          emergency_contact: %{},
          confidant_person: [],
          patient_signed: true,
          process_disclosure_data_consent: true,
          status: "active",
          inserted_by: UUID.generate(),
          updated_by: UUID.generate(),
          authentication_methods: [],
          merged_ids: []
        }
      end
    end
  end
end
