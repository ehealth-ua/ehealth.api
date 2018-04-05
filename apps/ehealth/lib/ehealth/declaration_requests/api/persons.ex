defmodule EHealth.DeclarationRequests.API.Persons do
  @moduledoc false

  def get_search_params(person_data) do
    birth_date = person_data["birth_date"]
    age = Timex.diff(Timex.now(), Date.from_iso8601!(birth_date), :years)

    search_params =
      cond do
        person_data["tax_id"] && birth_date ->
          %{
            "birth_date" => birth_date,
            "tax_id" => person_data["tax_id"]
          }

        age < 14 ->
          %{
            "birth_date" => birth_date,
            "birth_certificate" => get_birth_certificate(person_data["documents"])
          }

        true ->
          %{
            "first_name" => person_data["first_name"],
            "last_name" => person_data["last_name"],
            "birth_date" => birth_date
          }
      end

    Map.put(search_params, "status", "active")
  end

  defp get_birth_certificate(nil), do: nil

  defp get_birth_certificate(documents) do
    document = Enum.find(documents, &(Map.get(&1, "type") == "BIRTH_CERTIFICATE"))

    case document do
      %{"number" => number} -> number
      _ -> nil
    end
  end
end
