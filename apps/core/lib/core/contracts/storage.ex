defmodule Core.Contracts.Storage do
  @moduledoc false

  require Logger

  @media_storage_api Application.get_env(:core, :api_resolvers)[:media_storage]

  def save_signed_content(id, %{"signed_content" => signed_content}, headers, employee_id) do
    datetime =
      DateTime.utc_now()
      |> DateTime.to_unix()

    resource_name = "employee_update/#{employee_id}/#{datetime}"

    case @media_storage_api.store_signed_content(signed_content, :contract_bucket, id, resource_name, headers) do
      {:ok, _} -> :ok
      _error -> {:error, {:bad_gateway, "Failed to save signed content"}}
    end
  end

  def gen_relevant_get_links(id) do
    with {:ok, %{"data" => %{"secret_url" => secret_url}}} <-
           @media_storage_api.create_signed_url("GET", get_bucket(), "signed_content/signed_content", id, []) do
      {:ok, [%{"type" => "SIGNED_CONTENT", "url" => secret_url}]}
    else
      error ->
        Logger.error("Failed to generate contract document links with error: #{inspect(error)}")
        {:error, {:internal_server_error, "Failed to generate contract document links."}}
    end
  end

  defp get_bucket do
    Confex.fetch_env!(:core, Core.API.MediaStorage)[:contract_bucket]
  end
end
