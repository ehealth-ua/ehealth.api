defmodule Core.DeclarationRequests.API.V1.MpiSearch do
  @moduledoc """
  Provides mpi search
  """

  alias Core.DeclarationRequests.API.V1.Persons

  @rpc_worker Application.get_env(:core, :rpc_worker)

  def search(%{"auth_phone_number" => _} = search_params) do
    "mpi"
    |> @rpc_worker.run(MPI.Rpc, :search_persons, [search_params])
    |> search_result(:all)
  end

  def search(person) do
    with {:ok, search_params} <- Persons.get_search_params(person) do
      "mpi"
      |> @rpc_worker.run(MPI.Rpc, :search_persons, [search_params])
      |> search_result(:one)
    else
      {:error, :ignore} -> {:ok, nil}
      err -> err
    end
  end

  defp search_result({:ok, entries}, :all), do: {:ok, entries}
  defp search_result({:ok, [%{} = person]}, :one), do: {:ok, person}
  defp search_result({:ok, _}, :one), do: {:ok, nil}
  defp search_result(error, _), do: error
end
