defmodule EHealth.DeclarationRequest.API.Approve do
  @moduledoc false

  alias EHealth.API.MediaStorage
  alias EHealth.API.OTPVerification
  alias EHealth.DeclarationRequest
  require Logger

  @auth_na DeclarationRequest.authentication_method(:na)
  @auth_otp DeclarationRequest.authentication_method(:otp)
  @auth_offline DeclarationRequest.authentication_method(:offline)

  def verify(declaration_request, code) do
    case declaration_request.authentication_method_current do
      %{"type" => @auth_na} ->
        {:ok, true}

      %{"type" => @auth_otp, "number" => phone} ->
        OTPVerification.complete(phone, %{code: code})

      %{"type" => @auth_offline} ->
        check_documents(declaration_request.documents, declaration_request.id, {:ok, true})
    end
  end

  def check_documents([document | tail], declaration_request_id, acc) do
    case uploaded?(declaration_request_id, document) do
      # document is succesfully uploaded
      {:ok, true}
        -> check_documents(tail, declaration_request_id, acc)

      # document not found
      {:error, {:not_uploaded, document_type}}
        -> check_documents(tail, declaration_request_id, put_document_error(acc, document_type))

      # ael bad response
      {:error, {:ael_bad_response, _}} = err
        -> err
    end
  end

  def check_documents([], _declaration_request_id, acc) do
    acc
  end

  def uploaded?(id, %{"type" => type}) do
    resource_name = "declaration_request_#{type}.jpeg"
    bucket = Confex.fetch_env!(:ehealth, EHealth.API.MediaStorage)[:declaration_request_bucket]

    {:ok, %{"data" => %{"secret_url" => url}}} =
      MediaStorage.create_signed_url("HEAD", bucket, resource_name, id)

    Logger.info(fn -> inspect url end)
    case HTTPoison.head(url, ["Content-Type":  MIME.from_path(resource_name)]) do
      {:ok, resp} ->
        case resp do
          %HTTPoison.Response{status_code: 200} ->
            {:ok, true}
          _ ->
            {:error, {:not_uploaded, type}}
        end
      {:error, reason} ->
        Logger.error("Cannot check uploaded document in Ael with error #{inspect reason}")
        {:error, {:ael_bad_response, reason}}
    end
  end

  def put_document_error({:ok, true}, doc_type) do
    {:error, {:documents_not_uploaded, [doc_type]}}
  end

  def put_document_error({:error, {:documents_not_uploaded, container}}, doc_type) do
    {:error, {:documents_not_uploaded, container ++ [doc_type]}}
  end
end
