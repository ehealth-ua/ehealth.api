defmodule Core.DeclarationRequests.API.V2.MpiSearch do
  @moduledoc """
  Provides mpi search
  """

  alias Core.DeclarationRequests.API.V1.Persons

  @mpi_api Application.get_env(:core, :api_resolvers)[:mpi]

  def search(%{"auth_phone_number" => _} = search_params) do
    search_params
    |> @mpi_api.search([])
    |> search_result(:all)
  end

  def search(person, headers \\ []) do
    with {:ok, search_params} <- Persons.get_search_params(person) do
      search_params
      |> @mpi_api.search(headers)
      |> search_result(:one)
    else
      {:error, :ignore} -> {:ok, nil}
      err -> err
    end
  end

  defp search_result({:ok, %{"data" => data}}, :all), do: {:ok, data}
  defp search_result({:ok, %{"data" => [person | _]}}, :one), do: {:ok, person}
  defp search_result({:ok, %{"data" => _}}, :one), do: {:ok, nil}
  defp search_result({:error, %HTTPoison.Error{reason: reason}}, _), do: {:error, reason}
  defp search_result(error, _), do: error
end
