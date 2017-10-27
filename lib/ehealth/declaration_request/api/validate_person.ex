defmodule EHealth.DeclarationRequest.API.ValidatePerson do
  @moduledoc "Additional validation of Person request structure that cannot be covered by JSON Schema"

  alias EHealth.Validators.JsonObjects
  alias EHealth.Dictionaries

  @validation_dictionaries [
    "DOCUMENT_TYPE",
    "PHONE_TYPE",
    "AUTHENTICATION_METHOD",
    "DOCUMENT_RELATIONSHIP_TYPE"]

  @auth_method_error "Must be one and only one authentication method."

  def validate(person) do
    dict_keys = Dictionaries.get_dictionaries_keys(@validation_dictionaries)

    with %{"DOCUMENT_TYPE" => doc_types} = dict_keys,
         :ok <- JsonObjects.array_unique_by_key(person, ["documents"], "type", doc_types),
         %{"PHONE_TYPE" => phone_types} = dict_keys,
         :ok <- validate_person_phones(person, phone_types),
         :ok <- JsonObjects.array_unique_by_key(person, ["emergency_contact", "phones"], "type", phone_types),
         %{"AUTHENTICATION_METHOD" => auth_methods} = dict_keys,
         :ok <- validate_auth_method(person, auth_methods),
         :ok <- validate_confidant_persons(person, dict_keys)
    do
         :ok
    else
         {:error, [{rules, path}]} -> {:error, [{rules, JsonObjects.combine_path("person", path)}]}
    end
  end

  defp validate_person_phones(person, phone_types) do
    case Map.get(person, "phones") do
      nil    -> :ok
      []     -> :ok
      _phones -> JsonObjects.array_unique_by_key(person, ["phones"], "type", phone_types)
    end
  end

  defp validate_auth_method(person, auth_methods) do
    case JsonObjects.array_single_item(person, ["authentication_methods"], "type", auth_methods) do
      :ok                      -> :ok
      {:error, [{%{description: description} = descr, path}]} ->
        if description =~ "not found" do
          {:error, [{descr, path}]}
        else
          {:error, [{JsonObjects.get_error(@auth_method_error, auth_methods), path}]}
        end
    end
  end

  defp validate_confidant_persons(%{"confidant_person" => nil}, _), do:  :ok
  defp validate_confidant_persons(%{"confidant_person" => []}, _), do:   :ok
  defp validate_confidant_persons(person, dict_keys) when is_map(person) do
    valid_relations = ["PRIMARY", "SECONDARY"]
    confidant_persons = Map.get(person, "confidant_person")

    with :ok <- JsonObjects.array_unique_by_key(person, ["confidant_person"], "relation_type", valid_relations),
         :ok <- JsonObjects.array_item_required(person, ["confidant_person"], "relation_type", "PRIMARY"),
         :ok <- validate_every_confidant_person(confidant_persons, dict_keys, 0),
    do:  :ok
  end

  defp validate_every_confidant_person([], _, _), do: :ok
  defp validate_every_confidant_person([h | t], dict_keys, i) do
    with  %{"DOCUMENT_TYPE" => doc_types} = dict_keys,
          :ok <- JsonObjects.array_unique_by_key(h, ["documents_person"], "type", doc_types),
          %{"PHONE_TYPE" => phone_types} = dict_keys,
          :ok <- validate_person_phones(h, phone_types),
          %{"DOCUMENT_RELATIONSHIP_TYPE" => doc_relation_type} = dict_keys,
          :ok <- JsonObjects.array_unique_by_key(h, ["documents_relationship"], "type", doc_relation_type)
    do
          validate_every_confidant_person(t, dict_keys, i + 1)
    else
          {:error, [{rules, path}]} -> {:error, [{rules, JsonObjects.combine_path("confidant_person[#{i}]", path)}]}
    end
  end
end
