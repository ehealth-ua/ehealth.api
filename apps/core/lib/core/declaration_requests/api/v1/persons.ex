defmodule Core.DeclarationRequests.API.Persons do
  @moduledoc false

  @person_active "active"

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
          %{}

        true ->
          %{
            "first_name" => person_data["first_name"],
            "last_name" => person_data["last_name"],
            "birth_date" => birth_date
          }
      end

    if search_params == %{} do
      {:error, :ignore}
    else
      search_params
      |> Map.put("status", @person_active)
      |> maybe_put("unzr", person_data["unzr"])
      |> wrap_ok()
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp wrap_ok(value), do: {:ok, value}
end
