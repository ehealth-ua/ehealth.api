defmodule EHealth.DeclarationRequest.API.Approve do
  @moduledoc false

  alias EHealth.API.MediaStorage
  alias EHealth.API.OTPVerification
  require Logger

  @files_storage_bucket Confex.fetch_env!(:ehealth, EHealth.API.MediaStorage)[:declaration_request_bucket]

  def verify(declaration_request, code) do
    case declaration_request.authentication_method_current do
      %{"type" => "NA"} ->
        {:ok, true}

      %{"type" => "OTP", "number" => phone} ->
        OTPVerification.complete(phone, %{code: code})

      %{"type" => "OFFLINE"} ->
        documents = declaration_request.documents

        uploaded? = fn document, _acc -> uploaded?(declaration_request.id, document) end

        Enum.reduce_while(documents, {:ok, true}, uploaded?)
    end
  end

  def uploaded?(id, %{"type" => type}) do
    {:ok, %{"data" => %{"secret_url" => url}}} =
      MediaStorage.create_signed_url("HEAD", @files_storage_bucket, "declaration_request_#{type}.jpeg", id)
    case HTTPoison.head(url) do
      {:ok, resp} ->
        case resp do
          %HTTPoison.Response{status_code: 200} ->
            {:cont, {:ok, true}}
          _ ->
            {:halt, {:error, {:not_uploaded, "Document #{type} is not uploaded"}}}
        end
      {:error, reason} ->
        Logger.error("Cannot check uploaded document in Ael with error #{inspect reason}")
        {:halt, {:error, {:ael_bad_response, reason}}}
    end
  end
end
