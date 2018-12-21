defmodule Core.DeclarationRequests.API.V2.Persons do
  @moduledoc false

  alias Core.Validators.Error

  @person_active "active"
  def child_document_search_params(person) do
    number =
      person
      |> Map.get("documents", [])
      |> Enum.reduce_while("", fn
        %{"type" => "BIRTH_CERTIFICATE", "number" => number}, _ -> {:halt, number}
        _, acc -> {:cont, acc}
      end)

    digits = Regex.replace(~r/[^0-9]/iu, number, "")

    if digits != "" do
      {:ok,
       %{
         "birth_date" => person["birth_date"],
         "last_name" => person["last_name"] |> String.replace(~r{\s+}, "") |> String.downcase(),
         "documents" => [
           %{
             "type" => "BIRTH_CERTIFICATE",
             "digits" => digits
           }
         ],
         "status" => @person_active
       }}
    else
      Error.dump("BIRTH CERTIFICATE should contain digits")
    end
  end

  def adult_document_search_params(person) do
    documents = Map.get(person, "documents")

    %{"documents" => documents, "status" => @person_active}
  end

  def get_search_params(person_data) do
    birth_date = person_data["birth_date"]
    tax_id = person_data["tax_id"]

    age = Timex.diff(Timex.now(), Date.from_iso8601!(birth_date), :years)

    birth_date_tax_id_params = %{
      "birth_date" => birth_date,
      "tax_id" => tax_id,
      "status" => @person_active
    }

    cond do
      age < 14 && tax_id && birth_date ->
        with {:ok, birth_certificate_number_params} <- child_document_search_params(person_data) do
          {:ok,
           [
             birth_date_tax_id_params,
             birth_certificate_number_params
           ]}
        end

      age < 14 ->
        with {:ok, birth_certificate_number_params} <- child_document_search_params(person_data) do
          {:ok, [birth_certificate_number_params]}
        end

      age > 14 && tax_id && birth_date ->
        {:ok, [birth_date_tax_id_params]}

      age > 14 ->
        {:ok, [adult_document_search_params(person_data)]}
    end
  end
end
