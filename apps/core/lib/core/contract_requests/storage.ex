defmodule Core.ContractRequests.Storage do
  @moduledoc false

  alias Core.API.MediaStorage
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.ContractRequests.RequestPack
  alias Core.Validators.Signature, as: SignatureValidator
  alias Ecto.UUID

  require Logger

  @signature_api Application.get_env(:core, :api_resolvers)[:digital_signature]
  @media_storage_api Application.get_env(:core, :api_resolvers)[:media_storage]

  @signed_content %{
    dictionary_name: "SIGNED_CONTENT",
    permanent_path: "signed_content/signed_content"
  }

  @statute %{
    request_param_key: "statute_md5",
    dictionary_name: "CONTRACT_REQUEST_STATUTE",
    permanent_path: "media/contract_request_statute.pdf",
    upload_path: "media/upload_contract_request_statute.pdf"
  }

  @additional_document %{
    request_param_key: "additional_document_md5",
    dictionary_name: "CONTRACT_REQUEST_ADDITIONAL_DOCUMENT",
    permanent_path: "media/contract_request_additional_document.pdf",
    upload_path: "media/upload_contract_request_additional_document.pdf"
  }

  def draft do
    id = UUID.generate()

    with {:ok, %{secret_url: statute_url}} <-
           @media_storage_api.create_signed_url("PUT", get_bucket(), @statute.upload_path, id),
         {:ok, %{secret_url: additional_document_url}} <-
           @media_storage_api.create_signed_url("PUT", get_bucket(), @additional_document.upload_path, id) do
      %{
        "id" => id,
        "statute_url" => statute_url,
        "additional_document_url" => additional_document_url
      }
    end
  end

  def gen_relevant_get_links(id, status) do
    Enum.reduce_while(get_document_attributes_by_status(status), {:ok, []}, fn doc, {:ok, acc} ->
      with {:ok, %{secret_url: secret_url}} <-
             @media_storage_api.create_signed_url("GET", get_bucket(), doc.permanent_path, id) do
        case file_uploaded?(secret_url) do
          true -> {:cont, {:ok, [%{"type" => doc.dictionary_name, "url" => secret_url} | acc]}}
          _ -> {:cont, {:ok, acc}}
        end
      else
        error ->
          Logger.error("Failed to generate contract request document links with error: #{inspect(error)}")
          {:halt, {:error, {:internal_server_error, "Failed to generate contract request document links."}}}
      end
    end)
  end

  # TODO: We should use better way to determine file existence
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
        resource_name,
        bucket \\ :contract_request_bucket
      ) do
    case @media_storage_api.store_signed_content(content, bucket, id, resource_name) do
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
    with {:ok, %{secret_url: secret_url}} <-
           @media_storage_api.create_signed_url(
             "GET",
             MediaStorage.config()[:contract_request_bucket],
             @signed_content.permanent_path,
             id
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

  def resolve_partially_signed_content_url(contract_request_id) do
    bucket = get_bucket()
    resource_name = "contract_request_content.pkcs7"

    media_storage_response =
      @media_storage_api.create_signed_url(
        "GET",
        bucket,
        contract_request_id,
        resource_name
      )

    case media_storage_response do
      {:ok, %{secret_url: url}} -> {:ok, url}
      _ -> {:error, :media_storage_error}
    end
  end

  def move_uploaded_documents(%RequestPack{} = pack) do
    Enum.reduce_while([@statute, @additional_document], :ok, fn doc, _ ->
      case md5_request_param_exist?(pack, doc.request_param_key) do
        true -> move_file(pack, doc.upload_path, doc.permanent_path)
        false -> {:cont, :ok}
      end
    end)
  end

  defp move_file(%RequestPack{contract_request_id: id}, temp_resource_name, resource_name) do
    with {:ok, %{secret_url: url}} <- @media_storage_api.create_signed_url("GET", get_bucket(), temp_resource_name, id),
         {:ok, %{body: signed_content}} <- @media_storage_api.get_signed_content(url),
         {:ok, _} <- @media_storage_api.save_file(id, signed_content, get_bucket(), resource_name),
         {:ok, %{secret_url: url}} <-
           @media_storage_api.create_signed_url("DELETE", get_bucket(), temp_resource_name, id),
         {:ok, _} <- @media_storage_api.delete_file(url) do
      {:cont, :ok}
    else
      _ -> {:halt, {:error, {:conflict, "Failed to move uploaded documents"}}}
    end
  end

  def copy_contract_request_documents(new_contract_request_id, prev_contract_request_id) do
    Enum.reduce_while([@statute, @additional_document], :ok, fn doc, _ ->
      with {:ok, %{secret_url: url}} <-
             @media_storage_api.create_signed_url("GET", get_bucket(), doc.permanent_path, prev_contract_request_id),
           {:ok, %{body: signed_content}} <- @media_storage_api.get_signed_content(url),
           {:ok, _} <-
             @media_storage_api.save_file(
               new_contract_request_id,
               signed_content,
               get_bucket(),
               doc.permanent_path
             ) do
        {:cont, :ok}
      else
        _ -> {:halt, {:error, {:conflict, "Failed to copy contract request documents"}}}
      end
    end)
  end

  defp md5_request_param_exist?(%{decoded_content: decoded_content}, key), do: Map.has_key?(decoded_content, key)

  defp get_bucket do
    Confex.fetch_env!(:core, MediaStorage)[:contract_request_bucket]
  end
end
