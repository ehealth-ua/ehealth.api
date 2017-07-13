defmodule EHealth.DeclarationRequest.API.Approve do
  @moduledoc false

  alias EHealth.API.MediaStorage
  alias EHealth.API.OTPVerification

  @files_storage_bucket Confex.get_map(:ehealth, EHealth.API.MediaStorage)[:declaration_request_bucket]

  def verify(declaration_request, code) do
    case declaration_request.authentication_method_current do
      %{"type" => "OTP", "number" => phone} ->
        OTPVerification.complete(phone, %{code: code})
      %{"type" => "OFFLINE"} ->
        documents = declaration_request.documents

        uploaded? = fn document, _acc -> uploaded?(declaration_request.id, document) end

        documents
        |> Enum.filter(&(&1["verb"] == "HEAD"))
        |> Enum.reduce_while({:ok, true}, uploaded?)
    end
  end

  def uploaded?(id, document) do
    {:ok, %{"data" => %{"secret_url" => url}}} =
      MediaStorage.create_signed_url("HEAD", @files_storage_bucket, "declaration_request_#{document["type"]}.jpeg", id)

    case HTTPoison.head(url) do
      {:ok, resp} ->
        case resp do
          %HTTPoison.Response{status_code: 200} ->
            {:cont, {:ok, true}}
          _ ->
            {:halt, {:error, document}}
        end
      {:error, _} = unexpected_error ->
        {:halt, unexpected_error}
    end
  end
end
