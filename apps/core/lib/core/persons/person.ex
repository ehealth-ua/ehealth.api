defmodule Core.Persons.Person do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:version, :string, default: "default")
    field(:first_name, :string)
    field(:last_name, :string)
    field(:second_name, :string)
    field(:birth_date, :date)
    field(:birth_country, :string)
    field(:birth_settlement, :string)
    field(:gender, :string)
    field(:email, :string)
    field(:tax_id, :string)
    field(:unzr, :string)
    field(:death_date, :date)
    field(:preferred_way_communication, :string)
    field(:invalid_tax_id, :boolean, default: false)
    field(:is_active, :boolean, default: true)
    field(:documents, {:array, :map})
    field(:addresses, {:array, :map})
    field(:phones, {:array, :map})
    field(:secret, :string)
    field(:emergency_contact, :map)
    field(:confidant_person, {:array, :map})
    field(:patient_signed, :boolean, default: true)
    field(:process_disclosure_data_consent, :boolean)
    field(:status, :string, default: "active")
    field(:inserted_by, :string, default: "default")
    field(:updated_by, :string, default: "default")
    field(:authentication_methods, {:array, :map})
    field(:master_persons, {:array, :map})
    field(:merged_persons, {:array, :map})
    field(:no_tax_id, :boolean, default: false)

    timestamps(type: :utc_datetime_usec)
  end

  @fields_required ~w(
    version
    birth_date
    birth_country
    birth_settlement
    gender
    secret
    documents
    addresses
    authentication_methods
    emergency_contact
    process_disclosure_data_consent
    status
    inserted_by
    updated_by
  )a

  @fields_optional ~w(
    second_name
    email
    tax_id
    unzr
    death_date
    preferred_way_communication
    invalid_tax_id
    phones
    confidant_person
    master_persons
    merged_persons
  )a

  def changeset(params) do
    %__MODULE__{}
    |> cast(params, @fields_required ++ @fields_optional)
    |> validate_required(@fields_required)
  end
end
