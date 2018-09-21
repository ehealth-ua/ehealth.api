defmodule Core.DeclarationRequests.API.V2.MpiSearch do
  @moduledoc """
  provides mpi serch
  """
  alias Core.DeclarationRequests.API.Persons
  @mpi_api Application.get_env(:core, :api_resolvers)[:mpi]

  def search(person) do
    person
    |> Persons.get_search_params()
    |> @mpi_api.search([])
    |> search_result()
  end

  defp search_result({:ok, %{"data" => [person | _]}}), do: {:ok, person}
  defp search_result({:ok, %{"data" => _}}), do: {:ok, nil}
  defp search_result({:error, %HTTPoison.Error{reason: reason}}), do: {:error, reason}
  defp search_result(error), do: error
end
