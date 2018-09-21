defmodule Core.DeclarationRequests.API.Documents do
  @moduledoc false

  alias Core.API.MediaStorage
  alias Core.DeclarationRequests.DeclarationRequest

  @media_storage_api Application.get_env(:core, :api_resolvers)[:media_storage]

  def generate_links(%DeclarationRequest{id: id, documents: nil}) do
    render_links(id, ["GET"], [])
  end

  def generate_links(%DeclarationRequest{id: id, documents: documents}) do
    render_links(id, ["GET"], Enum.map(documents, &Map.get(&1, "type")))
  end

  def generate_links(%DeclarationRequest{id: declaration_request_id, data: %{"person" => person}}, http_verbs) do
    documents_list = gather_documents_list(person)
    render_links(declaration_request_id, http_verbs, documents_list)
  end

  def render_links(declaration_request_id, http_verbs, documents_list) do
    bucket = Confex.fetch_env!(:core, MediaStorage)[:declaration_request_bucket]

    link_versions =
      for verb <- http_verbs,
          document_type <- documents_list,
          do: {verb, document_type}

    documents =
      Enum.reduce_while(link_versions, [], fn {verb, document_type}, acc ->
        result =
          @media_storage_api.create_signed_url(
            verb,
            bucket,
            "declaration_request_#{document_type}.jpeg",
            declaration_request_id,
            []
          )

        case result do
          {:ok, %{"data" => %{"secret_url" => url}}} ->
            url_details = %{
              "type" => document_type,
              "verb" => verb,
              "url" => url
            }

            {:cont, [url_details | acc]}

          {:error, error_response} ->
            {:halt, {:error, error_response}}
        end
      end)

    case documents do
      {:error, error_response} ->
        {:error, error_response}

      _ ->
        {:ok, documents}
    end
  end

  def gather_documents_list(person) do
    # Removed person.DECLARATION_FORM
    person_documents = if person["tax_id"], do: ["person.tax_id"], else: []

    person_documents = person_documents ++ Enum.map(person["documents"], &"person.#{&1["type"]}")

    has_birth_certificate =
      Enum.reduce_while(person["documents"], false, fn document, acc ->
        if document["type"] == "BIRTH_CERTIFICATE", do: {:halt, true}, else: {:cont, acc}
      end)

    person
    |> Map.get("confidant_person", [])
    |> Enum.with_index()
    |> Enum.reduce({person_documents, has_birth_certificate}, &gather_confidant_documents/2)
    |> elem(0)
    |> Enum.uniq()
  end

  defp gather_confidant_documents({cp, idx}, {documents, has_birth_certificate}) do
    confidant_documents =
      cp["documents_relationship"]
      |> Enum.reduce([], fn doc, acc ->
        # skip BIRTH_CERTIFICATE if it was already added in person documents
        if doc["type"] == "BIRTH_CERTIFICATE" && has_birth_certificate do
          acc
        else
          ["confidant_person.#{idx}.#{cp["relation_type"]}.RELATIONSHIP.#{doc["type"]}" | acc]
        end
      end)
      |> Enum.reverse()
      |> Kernel.++(documents)

    {confidant_documents, has_birth_certificate}
  end
end
