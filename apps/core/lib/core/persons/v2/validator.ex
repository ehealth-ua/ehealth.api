defmodule Core.Persons.V2.Validator do
  @moduledoc "Additional validation of Person request structure that cannot be covered by JSON Schema"

  alias Core.Persons.V1.Validator, as: V1Validator
  alias Core.ValidationError
  alias Core.Validators.Error
  alias Core.Validators.JsonObjects

  def validate(person) do
    with :ok <- validate_tax_id(person),
         :ok <- validate_unzr(person),
         :ok <- validate_national_id(person),
         :ok <- validate_birth_certificate_number(person),
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

  def validate_unzr(%{"birth_date" => _, "unzr" => nil}), do: :ok

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

  defdelegate(validate_birth_date(birth_date, path), to: V1Validator)

  defdelegate validate_authentication_method_phone_number(authentication_methods, headers), to: V1Validator

  defdelegate validate_birth_certificate_number(person), to: V1Validator

  defdelegate validate_person_phones(person), to: V1Validator

  defdelegate validate_auth_method(person), to: V1Validator

  defdelegate validate_confidant_persons(person), to: V1Validator

  defdelegate validate_person_passports(person), to: V1Validator
end
