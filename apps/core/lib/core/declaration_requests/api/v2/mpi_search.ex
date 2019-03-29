defmodule Core.DeclarationRequests.API.V2.MpiSearch do
  @moduledoc """
  Provides mpi search
  """

  @rpc_worker Application.get_env(:core, :rpc_worker)

  def search(%{"auth_phone_number" => _} = search_params) do
    "mpi"
    |> @rpc_worker.run(MPI.Rpc, :search_persons, [search_params])
    |> search_result(:all)
  end

  def search(person_search_params) when is_list(person_search_params) do
    Enum.reduce_while(person_search_params, {:ok, nil}, fn search_params_set, acc ->
      case "mpi"
           |> @rpc_worker.run(MPI.Rpc, :search_persons, [search_params_set])
           |> search_result(:one) do
        {:ok, nil} -> {:cont, acc}
        {:ok, person} -> {:halt, {:ok, person}}
        err -> {:halt, err}
      end
    end)
  end

  defp search_result({:ok, entries}, :all), do: {:ok, entries}
  defp search_result({:ok, [%{} = person | _]}, :one), do: {:ok, person}
  defp search_result({:ok, []}, :one), do: {:ok, nil}
  defp search_result(error, _), do: error
end
