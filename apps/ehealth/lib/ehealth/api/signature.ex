defmodule EHealth.API.Signature do
  @moduledoc """
  Signature validator and data mapper
  """
  use EHealth.API.Helpers.MicroserviceBase

  alias EHealth.API.ResponseDecoder
  import EHealth.Utils.Connection, only: [get_header: 2]

  @behaviour EHealth.API.SignatureBehaviour

  def decode_and_validate(signed_content, signed_content_encoding, headers) do
    if config()[:enabled] do
      params = %{
        "signed_content" => signed_content,
        "signed_content_encoding" => signed_content_encoding
      }

      post!("/digital_signatures", Poison.encode!(params), headers)
    else
      with {:ok, binary} <- Base.decode64(signed_content),
           {:ok, data} <- Poison.decode(binary) do
        data_is_valid_resp(data, headers)
      else
        _ ->
          data_is_invalid_resp()
      end
    end
  end

  defp data_is_valid_resp(data, headers) do
    data =
      %{
        "content" => data,
        "is_valid" => true,
        "signer" => %{
          "drfo" => get_header(headers, "drfo"),
          "edrpou" => get_header(headers, "edrpou"),
          "surname" => headers |> get_header("surname") |> uri_decode(),
          "given_name" => headers |> get_header("given_name") |> uri_decode()
        }
      }
      |> wrap_response(200)
      |> Poison.encode!()

    ResponseDecoder.check_response(%HTTPoison.Response{body: data, status_code: 200})
  end

  defp uri_decode(string) when is_binary(string), do: string |> URI.decode()
  defp uri_decode(string), do: string

  defp data_is_invalid_resp do
    data =
      %{"is_valid" => false}
      |> wrap_response(422)
      |> Poison.encode!()

    ResponseDecoder.check_response(%HTTPoison.Response{body: data, status_code: 422})
  end

  defp wrap_response(data, code) do
    %{
      "meta" => %{
        "code" => code,
        "type" => "list"
      },
      "data" => data
    }
  end
end
