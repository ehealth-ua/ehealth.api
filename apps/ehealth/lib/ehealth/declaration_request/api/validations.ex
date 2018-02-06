defmodule EHealth.DeclarationRequest.API.Validations do
  @moduledoc false

  import Ecto.Changeset
  import EHealth.Utils.TypesConverter, only: [string_to_integer: 1]

  alias EHealth.DeclarationRequest
  alias EHealth.API.OTPVerification
  alias EHealth.Validators.Addresses
  alias EHealth.Validators.BirthDate
  alias EHealth.Validators.TaxID
  alias EHealth.API.Signature
  alias EHealth.DeclarationRequest.SignRequest
  alias EHealth.Validators.JsonSchema
  alias EHealth.DeclarationRequest.API.ValidatePerson
  alias EHealth.Employees.Employee

  @auth_otp DeclarationRequest.authentication_method(:otp)

  @allowed_employee_specialities ["THERAPIST", "PEDIATRICIAN", "FAMILY_DOCTOR"]

  def validate_authentication_method_phone_number(changeset) do
    validate_change(changeset, :data, fn :data, data ->
      data
      |> get_in(["person", "authentication_methods"])
      |> Enum.map(& &1["phone_number"])
      |> Enum.filter(&(!is_nil(&1)))
      |> verify_phone_numbers()
    end)
  end

  defp verify_phone_numbers([]) do
    []
  end

  defp verify_phone_numbers(phone_numbers) do
    case Enum.any?(phone_numbers, &phone_number_verified?/1) do
      true -> []
      false -> [data: "The phone number is not verified."]
    end
  end

  defp phone_number_verified?(phone_number) do
    case OTPVerification.search(phone_number) do
      {:ok, _} ->
        true

      {:error, _} ->
        false

      result ->
        raise "Error during OTP Verification interaction. Result from OTP Verification: #{inspect(result)}"
    end
  end

  def validate_patient_birth_date(changeset) do
    validate_change(changeset, :data, fn :data, data ->
      data
      |> get_in(["person", "birth_date"])
      |> BirthDate.validate()
      |> case do
        true -> []
        false -> [data: "Invalid birth date."]
      end
    end)
  end

  def validate_patient_age(changeset, specialities, adult_age) do
    validate_change(changeset, :data, fn :data, data ->
      patient_birth_date =
        data
        |> get_in(["person", "birth_date"])
        |> Date.from_iso8601!()

      patient_age = Timex.diff(Timex.now(), patient_birth_date, :years)

      case Enum.any?(specialities, &belongs_to(patient_age, adult_age, &1)) do
        true -> []
        false -> [data: "Doctor speciality does not meet the patient's age requirement."]
      end
    end)
  end

  def belongs_to(age, adult_age, "THERAPIST"), do: age >= string_to_integer(adult_age)
  def belongs_to(age, adult_age, "PEDIATRICIAN"), do: age < string_to_integer(adult_age)
  def belongs_to(_age, _adult_age, "FAMILY_DOCTOR"), do: true

  def validate_schema(attrs) do
    JsonSchema.validate(:declaration_request, %{"declaration_request" => attrs})
  end

  def validate_person(person) do
    ValidatePerson.validate(person)
  end

  def validate_addresses(addresses) do
    Addresses.validate(addresses, "REGISTRATION")
  end

  def validate_legal_entity_employee(changeset, legal_entity, employee) do
    validate_change(changeset, :data, fn :data, _data ->
      case employee.legal_entity_id == legal_entity.id do
        true -> []
        false -> [data: "Employee does not belong to legal entity."]
      end
    end)
  end

  def validate_legal_entity_division(changeset, legal_entity, division) do
    validate_change(changeset, :data, fn :data, _data ->
      case division.legal_entity_id == legal_entity.id do
        true -> []
        false -> [data: "Division does not belong to legal entity."]
      end
    end)
  end

  def decode_and_validate_sign_request(params, headers) do
    params
    |> validate_sign_request()
    |> validate_signature(headers)
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

  def validate_signature(%Ecto.Changeset{valid?: true, changes: changes}, headers) do
    changes
    |> Map.get(:signed_declaration_request)
    |> Signature.decode_and_validate(Map.get(changes, :signed_content_encoding), headers)
  end

  def validate_signature(err), do: err

  def normalize_signature_error({:error, %{"meta" => %{"description" => error}}}) do
    %SignRequest{}
    |> cast(%{}, [:signed_legal_entity_request])
    |> add_error(:signed_legal_entity_request, error)
  end

  def normalize_signature_error(ok_resp), do: ok_resp

  def check_is_valid({:ok, %{"data" => %{"is_valid" => false, "validation_error_message" => error}}}) do
    {:error, {:bad_request, error}}
  end

  def check_is_valid({:ok, %{"data" => %{"is_valid" => true}} = result}) do
    {_empty_message, result} = pop_in(result, ["data", "validation_error_message"])
    {:ok, result}
  end

  def check_is_valid({:error, error}) do
    {:error, error}
  end

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

  def validate_scope(changeset) do
    scope =
      changeset
      |> get_field(:data)
      |> Map.get("scope")

    if scope in ["family_doctor"] do
      changeset
    else
      add_error(changeset, :"data.scope", "is invalid", validation: :inclusion, params: [scope])
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
      |> Enum.with_index()
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

  def validate_authentication_methods(changeset) do
    authentication_methods =
      changeset
      |> get_field(:data)
      |> get_in(["person", "authentication_methods"])

    if is_list(authentication_methods) && !Enum.empty?(authentication_methods) do
      authentication_methods
      |> Enum.reduce({0, changeset}, &validate_auth_method/2)
      |> elem(1)
    else
      changeset
    end
  end

  def validate_employee_type(changeset, employee) do
    if Employee.type(:doctor) == employee.employee_type do
      changeset
    else
      add_error(changeset, :"data.person.employee_id", "Employee ID must reference a doctor.")
    end
  end

  def validate_employee_speciality(%Employee{additional_info: additional_info}) do
    specialities = Map.get(additional_info, "specialities", [])

    if Enum.any?(specialities, fn s -> Map.get(s, "speciality") in @allowed_employee_specialities end) do
      :ok
    else
      alllowed_types = Enum.join(@allowed_employee_specialities, ", ")
      {:error, {:"422", "Employee's speciality does not belong to a doctor: #{alllowed_types}"}}
    end
  end

  defp validate_auth_method(%{"type" => @auth_otp} = method, {i, changeset}) do
    case Map.has_key?(method, "phone_number") do
      true ->
        {i + 1, changeset}

      false ->
        message = "required property phone_number was not present"
        {i + 1, add_error(changeset, :"data.person.authentication_methods.[#{i}].phone_number", message)}
    end
  end

  defp validate_auth_method(_, {i, changeset}) do
    {i + 1, changeset}
  end

  defp assert_address_count(enum, address_type, count) do
    if count == Enum.count(enum, fn %{"type" => type} -> type == address_type end) do
      :ok
    else
      {:error, address_type}
    end
  end
end
