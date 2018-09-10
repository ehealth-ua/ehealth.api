defmodule Core.Persons.V2.Validator do
  @moduledoc "Additional validation of Person request structure that cannot be covered by JSON Schema"

  alias Core.ValidationError
  alias Core.Validators.BirthDate
  alias Core.Validators.Error
  alias Core.Validators.JsonObjects

  @verification_api Application.get_env(:core, :api_resolvers)[:otp_verification]
  @auth_method_error "Must be one and only one authentication method."
  @birth_certificate_number_regex ~r/^([A-Za-zА-яіІїЇєЄґҐё\d\#\№\–\-\—\－\_\'\,\s\/\\\=\|\!\<\;\?\%\:\]\*\+\.\√])+$/u

  def validate(person) do
    with :ok <- validate_tax_id(person),
         :ok <- validate_unzr(person),
         :ok <- validate_national_id(person),
         :ok <- validate_birth_certificate_number(person),
         :ok <- JsonObjects.array_unique_by_key(person, ["documents"], "type"),
         :ok <- validate_person_phones(person),
         :ok <- JsonObjects.array_unique_by_key(person, ["emergency_contact", "phones"], "type"),
         :ok <- validate_auth_method(person),
         :ok <- validate_confidant_persons(person) do
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

  def validate_tax_id(%{"no_tax_id" => false, "tax_id" => tax_id}) when not is_nil(tax_id), do: :ok

  def validate_tax_id(%{"no_tax_id" => true} = person) do
    if is_nil(Map.get(person, "tax_id")) do
      :ok
    else
      %ValidationError{
        description: "Persons who refused the tax_id should be without tax_id",
        params: ["no_tax_id"],
        path: "$.person.tax_id"
      }
    end
  end

  def validate_tax_id(_person),
    do: %ValidationError{
      description: "Only persons who refused the tax_id could be without tax_id",
      params: ["tax_id"],
      path: "$.person.tax_id"
    }

  def validate_unzr(%{"birth_date" => birth_date, "unzr" => unzr}) do
    bdate = String.replace(birth_date, "-", "")

    if Regex.match?(~r/^(#{bdate}-\d{5})$/ui, unzr) do
      :ok
    else
      %ValidationError{
        description: "Birthdate or unzr is not correct",
        params: ["unzr"],
        path: "$.person.unzr"
      }
    end
  end

  def validate_unzr(_), do: :ok

  def validate_national_id(%{} = person) do
    national_id =
      person
      |> Map.get("documents", [])
      |> Enum.find(fn
        %{"type" => "NATIONAL_ID"} = national_id ->
          national_id

        _ ->
          nil
      end)

    unzr? = Map.has_key?(person, "unzr")

    if !national_id or unzr? do
      :ok
    else
      %ValidationError{
        description: "unzr is mandatory for document type NATIONAL_ID",
        params: ["unzr"],
        path: "$.person"
      }
    end
  end

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

  defp validate_person_phones(person) do
    case Map.get(person, "phones") do
      nil -> :ok
      [] -> :ok
      _phones -> JsonObjects.array_unique_by_key(person, ["phones"], "type")
    end
  end

  defp validate_auth_method(person) do
    case JsonObjects.array_single_item(person, ["authentication_methods"], "type") do
      :ok ->
        :ok

      %ValidationError{} = error ->
        %{error | description: @auth_method_error}
    end
  end

  defp validate_confidant_persons(%{"confidant_person" => [_ | _] = confidant_persons} = person) do
    with :ok <- JsonObjects.array_unique_by_key(person, ["confidant_person"], "relation_type"),
         :ok <- JsonObjects.array_item_required(person, ["confidant_person"], "relation_type", "PRIMARY"),
         :ok <- validate_every_confidant_person(confidant_persons, 0) do
      :ok
    end
  end

  defp validate_confidant_persons(person) do
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
