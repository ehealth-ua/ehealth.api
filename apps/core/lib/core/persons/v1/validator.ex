defmodule Core.Persons.V1.Validator do
  @moduledoc "Additional validation of Person request structure that cannot be covered by JSON Schema"

  alias Core.ValidationError
  alias Core.Validators.BirthDate
  alias Core.Validators.Error
  alias Core.Validators.JsonObjects

  @verification_api Application.get_env(:core, :api_resolvers)[:otp_verification]
  @auth_method_error "Must be one and only one authentication method."
  @birth_certificate_number_regex ~r/^([A-Za-zА-яіІїЇєЄґҐё\d\#\№\–\-\—\－\_\'\,\s\/\\\=\|\!\<\;\?\%\:\]\*\+\.\√])+$/u

  def validate(person) do
    with :ok <- validate_birth_certificate_number(person),
         :ok <- JsonObjects.array_unique_by_key(person, ["documents"], "type"),
         :ok <- validate_person_phones(person),
         :ok <- JsonObjects.array_unique_by_key(person, ["emergency_contact", "phones"], "type"),
         :ok <- validate_auth_method(person),
         :ok <- validate_confidant_persons(person),
         :ok <- validate_person_passports(person) do
      :ok
    else
      %ValidationError{path: path} = error ->
        Error.dump(%{error | path: JsonObjects.combine_path("person", path)})
    end
  end

  def validate_authentication_method_phone_number(authentication_methods, headers)
      when is_list(authentication_methods) do
    authentication_methods
    |> Enum.map(& &1["phone_number"])
    |> Enum.filter(&(!is_nil(&1)))
    |> verify_phone_numbers(headers)
  end

  def validate_authentication_method_phone_number(_, _), do: :ok

  defp verify_phone_numbers([], _), do: :ok

  defp verify_phone_numbers(phone_numbers, headers) do
    case Enum.any?(phone_numbers, &phone_number_verified?(&1, headers)) do
      true -> :ok
      false -> {:error, "The phone number is not verified."}
    end
  end

  defp phone_number_verified?(phone_number, headers) do
    case @verification_api.search(phone_number, headers) do
      {:ok, _} ->
        true

      {:error, _} ->
        false

      result ->
        raise "Error during OTP Verification interaction. Result from OTP Verification: #{inspect(result)}"
    end
  end

  def validate_birth_date(birth_date, path) when not is_nil(birth_date) do
    case BirthDate.validate(birth_date) do
      true ->
        :ok

      false ->
        Error.dump(%ValidationError{description: "Invalid birth date", path: path})
    end
  end

  def validate_birth_date(nil, _), do: :ok

  def validate_birth_certificate_number(%{} = person) do
    age = Timex.diff(Timex.now(), Date.from_iso8601!(person["birth_date"]), :years)

    {birth_certificate, document_index} =
      person
      |> Map.get("documents", [])
      |> Enum.with_index()
      |> Enum.find({%{}, 0}, fn {doc, _index} -> doc["type"] == "BIRTH_CERTIFICATE" end)

    birth_certificate_number = Map.get(birth_certificate, "number", false)

    cond do
      age < 14 && !birth_certificate_number ->
        %ValidationError{
          description: "Must contain required item.",
          params: ["BIRTH_CERTIFICATE"],
          path: "$.person.documents"
        }

      birth_certificate_number && !birth_certificate_number_valid?(birth_certificate_number) ->
        %ValidationError{
          description: "Birth certificate number is not valid",
          params: ["BIRTH_CERTIFICATE"],
          path: "$.person.documents[#{document_index}].number"
        }

      true ->
        :ok
    end
  end

  defp birth_certificate_number_valid?(birth_certificate_number) do
    Regex.match?(@birth_certificate_number_regex, birth_certificate_number)
  end

  def validate_person_phones(person) do
    case Map.get(person, "phones") do
      nil -> :ok
      [] -> :ok
      _phones -> JsonObjects.array_unique_by_key(person, ["phones"], "type")
    end
  end

  def validate_auth_method(person) do
    case JsonObjects.array_single_item(person, ["authentication_methods"], "type") do
      :ok ->
        :ok

      %ValidationError{} = error ->
        %{error | description: @auth_method_error}
    end
  end

  def validate_person_passports(%{} = person) do
    passports_count =
      person
      |> Map.get("documents", [])
      |> Enum.reduce(0, fn
        %{"type" => type}, acc when type in ~w(NATIONAL_ID PASSPORT) ->
          acc + 1

        _, acc ->
          acc
      end)

    if passports_count <= 1 do
      :ok
    else
      %ValidationError{
        description: "Person can have only new passport NATIONAL_ID or old PASSPORT",
        params: ["$.person.documents"],
        path: "$.person.documents"
      }
    end
  end

  def validate_confidant_persons(%{"confidant_person" => [_ | _] = confidant_persons} = person) do
    with :ok <- JsonObjects.array_unique_by_key(person, ["confidant_person"], "relation_type"),
         :ok <- JsonObjects.array_item_required(person, ["confidant_person"], "relation_type", "PRIMARY"),
         :ok <- validate_every_confidant_person(confidant_persons, 0) do
      :ok
    end
  end

  def validate_confidant_persons(person) do
    age =
      Timex.diff(
        Timex.now(),
        Date.from_iso8601!(person["birth_date"]),
        :years
      )

    if age < 14 do
      %ValidationError{
        description: "Confidant person is mandatory for children",
        path: "$.confidant_person"
      }
    else
      :ok
    end
  end

  defp validate_every_confidant_person([], _), do: :ok

  defp validate_every_confidant_person([h | t], i) do
    with :ok <- JsonObjects.array_unique_by_key(h, ["documents_person"], "type"),
         :ok <- validate_person_phones(h),
         :ok <- JsonObjects.array_unique_by_key(h, ["documents_relationship"], "type") do
      validate_every_confidant_person(t, i + 1)
    else
      %ValidationError{path: path} = error ->
        %{error | path: JsonObjects.combine_path("confidant_person[#{i}]", path)}
    end
  end
end
