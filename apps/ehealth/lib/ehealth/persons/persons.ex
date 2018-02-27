defmodule EHealth.Persons do
  @moduledoc false

  alias EHealth.API.MPI
  alias EHealth.Persons.Search

  def search(params, headers \\ []) do
    with %Ecto.Changeset{valid?: true, changes: changes} <- Search.changeset(params),
         search_params <- Map.put(changes, "status", "active"),
         {:ok, %{"data" => persons, "paging" => %{"total_pages" => 1}}} <- MPI.search(search_params, headers) do
      {:ok, persons, changes}
    else
      {:ok, %{"paging" => %{"total_pages" => _}} = paging} -> {:error, paging}
      error -> error
    end
  end
end
