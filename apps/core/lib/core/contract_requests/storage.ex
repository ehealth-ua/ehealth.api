defmodule Core.ContractRequests.Storage do
  @moduledoc false

  alias Core.API.MediaStorage
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.ContractRequests.RequestPack
  alias Core.Validators.Signature, as: SignatureValidator
  alias Ecto.UUID

  @signature_api Application.get_env(:core, :api_resolvers)[:digital_signature]
  @media_storage_api Application.get_env(:core, :api_resolvers)[:media_storage]

  @reimbursement "REIMBURSEMENT"

  @signed_content %{
    dictionary_name: "SIGNED_CONTENT",
    permanent_path: "signed_content/signed_content"
  }

  @statute %{
    dictionary_name: "CONTRACT_REQUEST_STATUTE",
    permanent_path: "media/contract_request_statute.pdf",
    upload_path: "media/upload_contract_request_statute.pdf"
  }

  @additional_document %{
    dictionary_name: "CONTRACT_REQUEST_ADDITIONAL_DOCUMENT",
    permanent_path: "media/contract_request_additional_document.pdf",
    upload_path: "media/upload_contract_request_additional_document.pdf"
  }

  def draft do
    id = UUID.generate()

    with {:ok, %{"data" => %{"secret_url" => statute_url}}} <-
           @media_storage_api.create_signed_url("PUT", get_bucket(), @statute.upload_path, id, []),
         {:ok, %{"data" => %{"secret_url" => additional_document_url}}} <-
           @media_storage_api.create_signed_url("PUT", get_bucket(), @additional_document.upload_path, id, []) do
      %{
        "id" => id,
        "statute_url" => statute_url,
        "additional_document_url" => additional_document_url
      }
    end
  end

  def gen_relevant_get_links(id, type, status) do
    Enum.reduce(get_document_attributes_by_status(status), [], fn doc, acc ->
      with {:ok, %{"data" => %{"secret_url" => secret_url}}} <-
             @media_storage_api.create_signed_url("GET", get_bucket(), doc.permanent_path, id, []) do
        # crooked nail for reimbursement contracts with optional documents
        if type == @reimbursement do
          case file_uploaded?(secret_url) do
            true -> [%{"type" => doc.dictionary_name, "url" => secret_url} | acc]
            _ -> acc
          end
        else
          [%{"type" => doc.dictionary_name, "url" => secret_url} | acc]
        end
      end
    end)
  end

  # crooked nail for reimbursement contracts with optional documents
  defp file_uploaded?(url) do
    case @media_storage_api.get_signed_content(url) do
      {:ok, %{status_code: 200, body: body}} -> !String.match?(body, ~r/<Error>/)
      _ -> false
    end
  end

  defp get_document_attributes_by_status(status) do
    cond do
      Enum.any?(
        ~w(new approved in_process pending_nhs_sign terminated declined)a,
        &(CapitationContractRequest.status(&1) == status)
      ) ->
        [@statute, @additional_document]

      Enum.any?(~w(signed nhs_signed)a, &(CapitationContractRequest.status(&1) == status)) ->
        [@statute, @additional_document, @signed_content]

      true ->
        []
    end
  end

  def save_signed_content(
        id,
        %{"signed_content" => content},
        headers,
        resource_name,
        bucket \\ :contract_request_bucket
      ) do
    case @media_storage_api.store_signed_content(content, bucket, id, resource_name, headers) do
      {:ok, _} -> :ok
      _error -> {:error, {:bad_gateway, "Failed to save signed content"}}
    end
  end

  def decode_signed_content(
        %{"signed_content" => signed_content, "signed_content_encoding" => encoding},
        headers,
        required_signatures_count \\ 1,
        required_stamps_count \\ 0
      ) do
    SignatureValidator.validate(signed_content, encoding, headers, required_signatures_count, required_stamps_count)
  end

  def decode_and_validate_signed_content(%{id: id}, headers) do
    with {:ok, %{"data" => %{"secret_url" => secret_url}}} <-
           @media_storage_api.create_signed_url(
             "GET",
             MediaStorage.config()[:contract_request_bucket],
             @signed_content.permanent_path,
             id,
             headers
           ),
         {:ok, %{body: content, status_code: 200}} <- @media_storage_api.get_signed_content(secret_url),
         {:ok, %{"data" => %{"content" => content}}} <-
           @signature_api.decode_and_validate(
             Base.encode64(content),
             "base64",
             headers
           ) do
      {:ok, content}
    end
  end

  def resolve_partially_signed_content_url(contract_request_id, headers) do
    bucket = get_bucket()
    resource_name = "contract_request_content.pkcs7"

    media_storage_response =
      @media_storage_api.create_signed_url(
        "GET",
        bucket,
        contract_request_id,
        resource_name,
        headers
      )

    case media_storage_response do
      {:ok, %{"data" => %{"secret_url" => url}}} -> {:ok, url}
      _ -> {:error, :media_storage_error}
    end
  end

  def move_uploaded_documents(%RequestPack{} = pack, headers) do
    Enum.reduce_while([@statute, @additional_document], :ok, fn doc, _ ->
      move_file(pack, doc.upload_path, doc.permanent_path, headers)
    end)
  end

  defp move_file(%RequestPack{contract_request_id: id}, temp_resource_name, resource_name, headers) do
    with {:ok, %{"data" => %{"secret_url" => url}}} <-
           @media_storage_api.create_signed_url("GET", get_bucket(), temp_resource_name, id, []),
         {:ok, %{body: signed_content}} <- @media_storage_api.get_signed_content(url),
         {:ok, _} <- @media_storage_api.save_file(id, signed_content, get_bucket(), resource_name, headers),
         {:ok, %{"data" => %{"secret_url" => url}}} <-
           @media_storage_api.create_signed_url("DELETE", get_bucket(), temp_resource_name, id, []),
         {:ok, _} <- @media_storage_api.delete_file(url) do
      {:cont, :ok}
    end
  end

  defp get_bucket do
    Confex.fetch_env!(:core, MediaStorage)[:contract_request_bucket]
  end
end
