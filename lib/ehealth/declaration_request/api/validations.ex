defmodule EHealth.DeclarationRequest.API.Validations do
  @moduledoc false

  alias EHealth.API.PRM
  alias EHealth.API.OTPVerification

  import Ecto.Changeset

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

  def validate_patient_age(changeset, adult_age) do
    validate_change changeset, :data, fn :data, data ->
      patient_birth_date = Date.from_iso8601! get_in(data, ["person", "birth_date"])

      patient_age = Timex.diff(Timex.now(), patient_birth_date, :years)

      doctor_specialities =
        data
        |> get_in(["employee_id"])
        |> PRM.get_employee_by_id()
        |> elem(1)
        |> get_in(["data", "specialities"])

      case Enum.any? doctor_specialities, &belongs_to(patient_age, adult_age, &1["speciality"]) do
        true -> []
        false -> [data: "Doctor speciality does not meet the patient's age requirement."]
      end
    end
  end

  def belongs_to(age, adult_age, "THERAPIST"), do: age >= adult_age
  def belongs_to(age, adult_age, "PEDIATRICIAN"), do: age < adult_age
  def belongs_to(_age, _adult_age, "FAMILY_DOCTOR"), do: true
end
