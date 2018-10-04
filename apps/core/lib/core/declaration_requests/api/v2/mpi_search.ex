defmodule Core.DeclarationRequests.API.V2.MpiSearch do
  @moduledoc """
  Provides mpi search
  """

  alias Core.DeclarationRequests.API.Persons

  @mpi_api Application.get_env(:core, :api_resolvers)[:mpi]

  def search(person) do
    with {:ok, search_params} <- Persons.get_search_params(person) do
      search_params
      |> @mpi_api.search([])
      |> search_result()
    else
      {:error, :ignore} -> {:ok, nil}
      err -> err
    end
  end

  defp search_result({:ok, %{"data" => [person | _]}}), do: {:ok, person}
  defp search_result({:ok, %{"data" => _}}), do: {:ok, nil}
  defp search_result({:error, %HTTPoison.Error{reason: reason}}), do: {:error, reason}
  defp search_result(error), do: error
end
