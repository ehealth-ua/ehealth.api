defmodule EHealth.DeclarationRequest.API.Approve do
  @moduledoc false

  alias EHealth.API.OTPVerification

  def verify(declaration_request, code) do
    case declaration_request.authentication_method_current do
      %{"type" => "OTP", "number" => phone} ->
        OTPVerification.complete(phone, %{code: code})
      %{"type" => "OFFLINE"} ->
        documents = declaration_request.documents

        uploaded? = fn document, _acc -> uploaded?(document) end

        documents
        |> Enum.filter(&(&1["verb"] == "HEAD"))
        |> Enum.reduce_while(true, uploaded?)
    end
  end

  def uploaded?(document) do
    case HTTPoison.head(document["url"]) do
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
