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

      post!("/digital_signatures", Jason.encode!(params), headers)
    else
      with {:ok, binary} <- Base.decode64(signed_content),
           {:ok, data} <- Jason.decode(binary) do
        data_is_valid_resp(data, headers)
      else
        _ ->
          data_is_invalid_resp()
      end
    end
  end

  defp data_is_valid_resp(data, headers) do
    signatures = [
      %{
        "is_valid" => true,
        "signer" => %{
          "drfo" => get_header(headers, "drfo"),
          "edrpou" => get_header(headers, "edrpou"),
          "surname" => headers |> get_header("surname") |> uri_decode(),
          "given_name" => headers |> get_header("given_name") |> uri_decode()
        },
        "validation_error_message" => ""
      }
    ]

    signatures =
      case get_header(headers, "msp_drfo") do
        nil ->
          signatures

        msp_drfo ->
          msp_signature = %{
            "is_valid" => true,
            "signer" => %{
              "drfo" => msp_drfo
            },
            "validation_error_message" => ""
          }

          [msp_signature | signatures]
      end

    data =
      %{
        "content" => data,
        "signatures" => signatures
      }
      |> wrap_response(200)
      |> Jason.encode!()

    ResponseDecoder.check_response(%HTTPoison.Response{body: data, status_code: 200})
  end

  defp uri_decode(string) when is_binary(string), do: string |> URI.decode()
  defp uri_decode(string), do: string

  defp data_is_invalid_resp do
    data =
      %{
        "error" => %{
          "invalid" => [
            %{
              "entry" => "$.signed_content",
              "entry_type" => "json_data_property",
              "rules" => [
                %{
                  "description" => "Not a base64 string",
                  "params" => [],
                  "rule" => "invalid"
                }
              ]
            }
          ],
          "message" =>
            "Validation failed. You can find validators description at our API Manifest:" <>
              " http://docs.apimanifest.apiary.io/#introduction/interacting-with-api/errors.",
          "type" => "validation_failed"
        },
        "meta" => %{
          "code" => 422,
          "request_id" => "2kmaguf9ec791885t40008s2",
          "type" => "object",
          "url" => "http://www.example.com/digital_signatures"
        }
      }
      |> Jason.encode!()

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
