defmodule EHealth.Persons.Validator do
  @moduledoc "Additional validation of Person request structure that cannot be covered by JSON Schema"

  alias EHealth.Validators.JsonObjects
  alias EHealth.Dictionaries

  @verification_api Application.get_env(:ehealth, :api_resolvers)[:otp_verification]
  @validation_dictionaries ["DOCUMENT_TYPE", "PHONE_TYPE", "AUTHENTICATION_METHOD", "DOCUMENT_RELATIONSHIP_TYPE"]
  @auth_method_error "Must be one and only one authentication method."
  @birth_certificate_number_regex ~r/^([A-Za-zА-яіІїЇєЄґҐё\d\#\№\–\-\—\－\_\'\,\s\/\\\=\|\!\<\;\?\%\:\]\*\+\.\√])+$/u

  def validate(person) do
    dict_keys = Dictionaries.get_dictionaries_keys(@validation_dictionaries)

    with :ok <- validate_birth_certificate_number(person),
         %{"DOCUMENT_TYPE" => doc_types} = dict_keys,
         :ok <- JsonObjects.array_unique_by_key(person, ["documents"], "type", doc_types),
         %{"PHONE_TYPE" => phone_types} = dict_keys,
         :ok <- validate_person_phones(person, phone_types),
         :ok <- JsonObjects.array_unique_by_key(person, ["emergency_contact", "phones"], "type", phone_types),
         %{"AUTHENTICATION_METHOD" => auth_methods} = dict_keys,
         :ok <- validate_auth_method(person, auth_methods),
         :ok <- validate_confidant_persons(person, dict_keys) do
      :ok
    else
      {:error, [{rules, path}]} ->
        {:error, [{rules, JsonObjects.combine_path("person", path)}]}
    end
  end

  # TODO: this should be done in addresses validator #2228
  def validate_addresses_types(addresses, types) do
    err = {:error, {:"422", "Addresses with types #{Enum.join(types, ", ")} should be present"}}

    Enum.reduce_while(types, :ok, fn type, _ ->
      if address_with_type_exists?(addresses, type), do: {:cont, :ok}, else: {:halt, err}
    end)
  end

  defp address_with_type_exists?(addresses, type) do
    Enum.reduce_while(addresses, false, fn %{"type" => address_type}, _ ->
      if address_type == type, do: {:halt, true}, else: {:cont, false}
    end)
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
        {:error, [{JsonObjects.get_error("Must contain required item.", "BIRTH_CERTIFICATE"), "$.person.documents"}]}

      birth_certificate_number && !birth_certificate_number_valid?(birth_certificate_number) ->
        {:error,
         [
           {JsonObjects.get_error("Birth certificate number is not valid", "BIRTH_CERTIFICATE"),
            "$.person.documents[#{document_index}].number"}
         ]}

      true ->
        :ok
    end
  end

  defp birth_certificate_number_valid?(birth_certificate_number) do
    Regex.match?(@birth_certificate_number_regex, birth_certificate_number)
  end

  defp validate_person_phones(person, phone_types) do
    case Map.get(person, "phones") do
      nil -> :ok
      [] -> :ok
      _phones -> JsonObjects.array_unique_by_key(person, ["phones"], "type", phone_types)
    end
  end

  defp validate_auth_method(person, auth_methods) do
    case JsonObjects.array_single_item(person, ["authentication_methods"], "type", auth_methods) do
      :ok ->
        :ok

      {:error, [{%{description: description} = descr, path}]} ->
        if description =~ "not found" do
          {:error, [{descr, path}]}
        else
          {:error, [{JsonObjects.get_error(@auth_method_error, auth_methods), path}]}
        end
    end
  end

  defp validate_confidant_persons(person, dict_keys) when is_map(person) do
    valid_relations = ["PRIMARY", "SECONDARY"]

    case Map.get(person, "confidant_person") do
      nil ->
        :ok

      [] ->
        :ok

      confidant_persons ->
        with :ok <- JsonObjects.array_unique_by_key(person, ["confidant_person"], "relation_type", valid_relations),
             :ok <- JsonObjects.array_item_required(person, ["confidant_person"], "relation_type", "PRIMARY"),
             :ok <- validate_every_confidant_person(confidant_persons, dict_keys, 0),
             do: :ok
    end
  end

  defp validate_every_confidant_person([], _, _), do: :ok

  defp validate_every_confidant_person([h | t], dict_keys, i) do
    with %{"DOCUMENT_TYPE" => doc_types} = dict_keys,
         :ok <- JsonObjects.array_unique_by_key(h, ["documents_person"], "type", doc_types),
         %{"PHONE_TYPE" => phone_types} = dict_keys,
         :ok <- validate_person_phones(h, phone_types),
         %{"DOCUMENT_RELATIONSHIP_TYPE" => doc_relation_type} = dict_keys,
         :ok <- JsonObjects.array_unique_by_key(h, ["documents_relationship"], "type", doc_relation_type) do
      validate_every_confidant_person(t, dict_keys, i + 1)
    else
      {:error, [{rules, path}]} -> {:error, [{rules, JsonObjects.combine_path("confidant_person[#{i}]", path)}]}
    end
  end
end
