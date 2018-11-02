defmodule GraphQLWeb.Resolvers.ContractResolver do
  @moduledoc false

  import GraphQLWeb.Resolvers.Helpers.Errors

  alias Core.Contracts

  def terminate(%{id: id, status_reason: status_reason}, %{context: %{headers: headers}}) do
    with {:ok, contract, _references} <- Contracts.terminate(id, %{"status_reason" => status_reason}, headers) do
      {:ok, %{contract: contract}}
    else
      # TODO: Remove after error handling is done
      {:error, {:forbidden, error}} ->
        {:error, format_forbidden_error(error)}

      {:error, {:conflict, error}} ->
        {:error, format_conflict_error(error)}

      {:error, {:not_found, error}} ->
        {:error, format_not_found_error(error)}

      error ->
        error
    end
  end
end
