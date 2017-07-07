defmodule EHealth.DeclarationRequest.API.Validations do
  @moduledoc false

  use JValid

  alias EHealth.API.OTPVerification
  alias EHealth.Validators.SchemaMapper
  alias EHealth.Validators.Addresses
  alias EHealth.Validators.BirthDate
  alias EHealth.Validators.TaxID

  import Ecto.Changeset

  use_schema :declaration_request, "specs/json_schemas/declaration_request_schema.json"

  def validate_patient_phone_number(changeset) do
    verified? =
      fn phone_number ->
        case OTPVerification.search(phone_number) do
          {:ok, _} -> true
          {:error, _} -> false
          result ->
            raise "Error during OTP Verification interaction. Result from OTP Verification: #{inspect result}"
        end
      end

    validate_change changeset, :data, fn :data, data ->
      phone_numbers =
        data
        |> get_in(["person", "phones"])
        |> Enum.map(&(&1["number"]))

      case Enum.any?(phone_numbers, verified?) do
        true -> []
        false -> [data: "The phone number is not verified."]
      end
    end
  end

  def validate_patient_birth_date(changeset) do
    validate_change changeset, :data, fn :data, data ->
      data
      |> get_in(["person", "birth_date"])
      |> BirthDate.validate()
      |> case do
        true -> []
        false -> [data: "Invalid birth date."]
      end
    end
  end

  def validate_patient_age(changeset, specialities, adult_age) do
    validate_change changeset, :data, fn :data, data ->
      patient_birth_date =
        data
        |> get_in(["person", "birth_date"])
        |> Date.from_iso8601!()

      patient_age = Timex.diff(Timex.now(), patient_birth_date, :years)

      case Enum.any? specialities, &belongs_to(patient_age, adult_age, &1) do
        true -> []
        false -> [data: "Doctor speciality does not meet the patient's age requirement."]
      end
    end
  end

  def belongs_to(age, adult_age, "THERAPIST"), do: age >= adult_age
  def belongs_to(age, adult_age, "PEDIATRICIAN"), do: age < adult_age
  def belongs_to(_age, _adult_age, "FAMILY_DOCTOR"), do: true

  def validate_schema(attrs) do
    schema =
      @schemas
      |> Keyword.get(:declaration_request)
      |> SchemaMapper.prepare_declaration_request_schema()

    case validate_schema(schema, %{"declaration_request" => attrs}) do
      :ok -> {:ok, attrs}
      err -> err
    end
  end

  def validate_addresses(addresses) do
    Addresses.validate(addresses)
  end

  def validate_legal_entity_employee(changeset, legal_entity, employee) do
    validate_change changeset, :data, fn :data, _data ->
      case employee["legal_entity_id"] == legal_entity["id"] do
        true -> []
        false -> [data: "Employee does not belong to legal entity."]
      end
    end
  end

  def validate_legal_entity_division(changeset, legal_entity, division) do
    validate_change changeset, :data, fn :data, _data ->
      case division["legal_entity_id"] == legal_entity["id"] do
        true -> []
        false -> [data: "Division does not belong to legal entity."]
      end
    end
  end

  def validate_tax_id(changeset) do
    tax_id =
      changeset
      |> get_field(:data)
      |> get_in(["person", "tax_id"])

    if TaxID.validate(tax_id) do
      changeset
    else
      add_error(changeset, :"data.person.tax_id", "Person's tax ID in not valid.")
    end
  end

  def validate_confidant_persons_tax_id(changeset) do
    confidant_persons =
      changeset
      |> get_field(:data)
      |> get_in(["person", "confidant_person"])

    validation = fn {%{"tax_id" => tax_id}, index}, changeset ->
      if TaxID.validate(tax_id) do
        changeset
      else
        add_error(changeset, :"data.person.confidant_person[#{index}].tax_id", "Person's tax ID in not valid.")
      end
    end

    confidant_persons
    |> Enum.with_index
    |> Enum.reduce(changeset, validation)
  end
end
