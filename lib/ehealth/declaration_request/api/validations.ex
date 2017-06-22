defmodule EHealth.DeclarationRequest.API.Validations do
  @moduledoc false

  use JValid

  alias EHealth.API.OTPVerification
  alias EHealth.Utils.ValidationSchemaMapper

  import Ecto.Changeset

  use_schema :declaration_request, "specs/json_schemas/declaration_request_schema.json"

  def validate_patient_phone_number(changeset) do
    verified? =
      fn phone_number ->
        result = OTPVerification.search(%{
          number: phone_number,
          statuses: "completed"
        })

        case result do
          {:ok, %{"data" => [_|_]}} -> true
          {:ok, %{"data" => []}} -> false
          _ ->
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

  def validate_patient_age(changeset, specialities, adult_age) do
    validate_change changeset, :data, fn :data, data ->
      patient_birth_date = Date.from_iso8601! get_in(data, ["person", "birth_date"])

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
      |> ValidationSchemaMapper.prepare_declaration_request_schema()

    case validate_schema(schema, attrs) do
      :ok -> {:ok, attrs}
      err -> err
    end
  end
end
