defmodule Core.Persons.V2.Validator do
  @moduledoc "Additional validation of Person request structure that cannot be covered by JSON Schema"

  alias Core.Persons.V1.Validator, as: V1Validator
  alias Core.ValidationError
  alias Core.Validators.Error
  alias Core.Validators.JsonObjects

  @expiration_date_document_types ~w(
    NATIONAL_ID
    COMPLEMENTARY_PROTECTION_CERTIFICATE
    PERMANENT_RESIDENCE_PERMIT
    REFUGEE_CERTIFICATE
    TEMPORARY_CERTIFICATE
    TEMPORARY_PASSPORT
  )

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
         :ok <- validate_person_passports(person),
         :ok <- validate_document_dates(person) do
      :ok
    else
      %ValidationError{path: path} = error ->
        Error.dump(%{error | path: JsonObjects.combine_path("person", path)})
    end
  end

  def validate_tax_id(%{"no_tax_id" => false, "tax_id" => tax_id} = person) do
    birth_date = Map.get(person, "birth_date")
    age = Timex.diff(Timex.now(), Date.from_iso8601!(birth_date), :years)

    if not is_nil(tax_id) or age < 14 do
      :ok
    else
      %ValidationError{
        description: "Only persons who refused the tax_id could be without tax_id",
        params: ["tax_id"],
        path: "$.person.tax_id"
      }
    end
  end

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

  defp validate_document_dates(%{"birth_date" => birth_date} = person) do
    birth_date = Date.from_iso8601!(birth_date)

    person
    |> Map.get("documents", [])
    |> Enum.with_index()
    |> Enum.reduce_while(:ok, fn {document, index}, acc ->
      issued_at = convert_date(document["issued_at"])
      expiration_date = convert_date(document["expiration_date"])

      with :ok <- validate_issued_at(issued_at, birth_date, index),
           :ok <- validate_expiration_date(expiration_date, document["type"], index) do
        {:cont, acc}
      else
        error ->
          {:halt, error}
      end
    end)
  end

  defp validate_issued_at(nil, _, _), do: :ok

  defp validate_issued_at(issued_at, birth_date, index) do
    with {_, true} <- {:today, Date.compare(issued_at, Date.utc_today()) != :gt},
         {_, true} <- {:birth_date, Date.compare(issued_at, birth_date) != :lt} do
      :ok
    else
      {:today, _} ->
        %ValidationError{
          description: "Document issued date should be in the past",
          params: [],
          path: "$.person.documents[#{index}].issued_at"
        }

      {:birth_date, _} ->
        %ValidationError{
          description: "Document issued date should greater than person.birth_date",
          params: [],
          path: "$.person.documents[#{index}].issued_at"
        }
    end
  end

  defp validate_expiration_date(nil, document_type, index) when document_type in @expiration_date_document_types do
    %ValidationError{
      description: "expiration_date is mandatory for document_type #{document_type}",
      params: [],
      path: "$.person.documents[#{index}].expiration_date"
    }
  end

  defp validate_expiration_date(nil, _, _), do: :ok

  defp validate_expiration_date(expiration_date, _, index) do
    if Date.compare(expiration_date, Date.utc_today()) != :lt do
      :ok
    else
      %ValidationError{
        description: "Document expiration_date should be in the future",
        params: [],
        path: "$.person.documents[#{index}].expiration_date"
      }
    end
  end

  defp convert_date(nil), do: nil

  defp convert_date(value) when is_binary(value) do
    with {:ok, date} <- Date.from_iso8601(value) do
      date
    else
      _ -> nil
    end
  end
end
