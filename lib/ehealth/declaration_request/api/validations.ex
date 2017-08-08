defmodule EHealth.DeclarationRequest.API.Validations do
  @moduledoc false

  use JValid

  import Ecto.Changeset
  import EHealth.Utils.TypesConverter, only: [string_to_integer: 1]

  alias EHealth.API.OTPVerification
  alias EHealth.Validators.SchemaMapper
  alias EHealth.Validators.Addresses
  alias EHealth.Validators.BirthDate
  alias EHealth.Validators.TaxID
  alias EHealth.API.Signature
  alias EHealth.DeclarationRequest.SignRequest

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

  def belongs_to(age, adult_age, "THERAPIST"), do: age >= string_to_integer(adult_age)
  def belongs_to(age, adult_age, "PEDIATRICIAN"), do: age < string_to_integer(adult_age)
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
      case employee.legal_entity_id == legal_entity.id do
        true -> []
        false -> [data: "Employee does not belong to legal entity."]
      end
    end
  end

  def validate_legal_entity_division(changeset, legal_entity, division) do
    validate_change changeset, :data, fn :data, _data ->
      case division.legal_entity_id == legal_entity.id do
        true -> []
        false -> [data: "Division does not belong to legal entity."]
      end
    end
  end

  def decode_and_validate_sign_request(params) do
    params
    |> validate_sign_request()
    |> validate_signature()
    |> normalize_signature_error()
    |> check_is_valid()
  end

  def validate_sign_request(params) do
    fields = ~W(
      signed_declaration_request
      signed_content_encoding
    )a

    %SignRequest{}
    |> cast(params, fields)
    |> validate_required(fields)
    |> validate_inclusion(:signed_content_encoding, ["base64"])
  end

  def validate_signature(%Ecto.Changeset{valid?: true, changes: changes}) do
    changes
    |> Map.get(:signed_declaration_request)
    |> Signature.decode_and_validate(Map.get(changes, :signed_content_encoding))
  end
  def validate_signature(err), do: err

  def normalize_signature_error({:error, %{"meta" => %{"description" => error}}}) do
    %SignRequest{}
    |> cast(%{}, [:signed_legal_entity_request])
    |> add_error(:signed_legal_entity_request, error)
  end
  def normalize_signature_error(ok_resp), do: ok_resp

  def check_is_valid({:ok, %{"data" => %{"is_valid" => false}}}) do
    {:error, {:bad_request, "Signed request data is invalid"}}
  end
  def check_is_valid({:ok, %{"data" => %{"is_valid" => true}}} = data), do: data

  def validate_tax_id(changeset) do
    tax_id =
      changeset
      |> get_field(:data)
      |> get_in(["person", "tax_id"])

    if is_nil(tax_id) || TaxID.validate(tax_id) do
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

    if is_list(confidant_persons) && !Enum.empty?(confidant_persons) do
      validation = fn {person, index}, changeset ->
        tax_id = person["tax_id"]

        if is_nil(tax_id) || TaxID.validate(tax_id) do
          changeset
        else
          add_error(changeset, :"data.person.confidant_person[#{index}].tax_id", "Person's tax ID in not valid.")
        end
      end

      confidant_persons
      |> Enum.with_index
      |> Enum.reduce(changeset, validation)
    else
      changeset
    end
  end

  def validate_person_addresses(changeset) do
    addresses =
      changeset
      |> get_field(:data)
      |> get_in(["person", "addresses"])

    with :ok <- assert_address_count(addresses, "REGISTRATION", 1),
         :ok <- assert_address_count(addresses, "RESIDENCE", 1) do
      changeset
    else
      {:error, "REGISTRATION"} ->
        add_error(changeset, :"data.person.addresses", "one and only one registration address is required")
      {:error, "RESIDENCE"} ->
        add_error(changeset, :"data.person.addresses", "one and only one residence address is required")
    end
  end

  def validate_confidant_person_rel_type(changeset) do
    confidant_persons =
      changeset
      |> get_field(:data)
      |> get_in(["person", "confidant_person"])

    if is_list(confidant_persons) && !Enum.empty?(confidant_persons) do
      if 1 == Enum.count(confidant_persons, fn %{"relation_type" => type} -> type == "PRIMARY" end) do
        changeset
      else
        message = "one and only one confidant person with type PRIMARY is required"
        add_error(changeset, :"data.person.confidant_persons[].relation_type", message)
      end
    else
      changeset
    end
  end

  defp assert_address_count(enum, address_type, count) do
    if count == Enum.count(enum, fn %{"type" => type} -> type == address_type end) do
      :ok
    else
      {:error, address_type}
    end
  end
end
