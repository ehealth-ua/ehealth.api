defmodule EHealth.DeclarationRequest.API.Images do
  @moduledoc false

  alias EHealth.DeclarationRequest
  alias EHealth.DeclarationRequest.API.Helpers
  alias EHealth.API.MediaStorage

  @files_storage_bucket Confex.fetch_env!(:ehealth, EHealth.API.MediaStorage)[:declaration_request_bucket]

  def generate_links(%DeclarationRequest{id: id, data: %{"person" => person}}) do
    documents_list = Helpers.gather_documents_list(person)

    link_versions =
      for verb <- ["GET"],
          document_type <- documents_list, do: {verb, document_type}

    documents =
      Enum.reduce_while link_versions, [], fn {verb, document_type}, acc ->
        result =
          MediaStorage.create_signed_url(verb, @files_storage_bucket, "declaration_request_#{document_type}.jpeg", id)

        case result do
          {:ok, %{"data" => %{"secret_url" => url}}} ->
            url_details = %{
              "type" => document_type,
              "verb" => verb,
              "url" => url
            }

            {:cont, [url_details|acc]}
          {:error, error_response} ->
            {:halt, {:error, error_response}}
        end
      end

    case documents do
      {:error, error_response} ->
        {:error, format_error_response("MediaStorage", error_response)}
      _ ->
        {:ok, documents}
    end
  end

  defp format_error_response(microservice, result) do
    "Error during #{microservice} interaction. Result from #{microservice}: #{inspect result}"
  end
end
