defmodule Core.DeclarationRequests.API.Persons do
  @moduledoc false

  @person_active "active"

  def get_search_params(person_data) do
    birth_date = person_data["birth_date"]
    unzr = person_data["unzr"]
    tax_id = person_data["tax_id"]

    age = Timex.diff(Timex.now(), Date.from_iso8601!(birth_date), :years)

    if age < 14 && !unzr && !tax_id do
      {:error, :ignore}
    else
      search_params =
        cond do
          tax_id && birth_date ->
            %{
              "birth_date" => birth_date,
              "tax_id" => tax_id
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
        |> put_search_params("unzr", unzr)
        |> put_search_params("status", @person_active)

      {:ok, search_params}
    end
  end

  defp put_search_params(map, _key, nil), do: map
  defp put_search_params(map, key, value), do: Map.put(map, key, value)
end
