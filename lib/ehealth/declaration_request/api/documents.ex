defmodule EHealth.DeclarationRequest.API.Documents do
  @moduledoc false

  alias EHealth.DeclarationRequest
  alias EHealth.DeclarationRequest.API.Helpers
  alias EHealth.API.MediaStorage

  def generate_links(%DeclarationRequest{id: declaration_request_id, data: %{"person" => person}}, http_verbs) do
    documents_list = Helpers.gather_documents_list(person)
    render_links(declaration_request_id, http_verbs, documents_list)
  end

  def render_links(declaration_request_id, http_verbs, documents_list) do
    bucket = Confex.fetch_env!(:ehealth, EHealth.API.MediaStorage)[:declaration_request_bucket]

    link_versions =
      for verb <- http_verbs,
          document_type <- documents_list, do: {verb, document_type}

    documents =
      Enum.reduce_while link_versions, [], fn {verb, document_type}, acc ->
        result =
          MediaStorage.create_signed_url(verb,
            bucket, "declaration_request_#{document_type}.jpeg", declaration_request_id)

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
    result
  end
end
