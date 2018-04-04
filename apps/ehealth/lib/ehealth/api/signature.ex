defmodule EHealth.API.Signature do
  @moduledoc """
  Signature validator and data mapper
  """
  require Logger

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.Helpers.HeadersProcessor

  alias EHealth.API.ResponseDecoder
  import EHealth.Utils.Connection, only: [get_header: 2]

  @behaviour EHealth.API.SignatureBehaviour

  def process_url(url), do: config()[:endpoint] <> url

  def decode_and_validate(signed_content, signed_content_encoding, headers) do
    if config()[:enabled] do
      params = %{
        "signed_content" => signed_content,
        "signed_content_encoding" => signed_content_encoding
      }

      result =
        "/digital_signatures"
        |> post!(Poison.encode!(params), headers, config()[:hackney_options])
        |> ResponseDecoder.check_response()

      {_, response} = result

      Logger.info(fn ->
        Poison.encode!(%{
          "log_type" => "microservice_response",
          "microservice" => "digital-signature",
          "result" => response,
          "request_id" => Logger.metadata()[:request_id]
        })
      end)

      result
    else
      data = Base.decode64(signed_content)

      case data do
        :error ->
          data_is_invalid_resp()

        {:ok, data} ->
          case Poison.decode(data) do
            {:ok, data} -> data_is_valid_resp(data, headers)
            _ -> data_is_invalid_resp()
          end
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
          "surname" => get_header(headers, "surname"),
          "given_name" => get_header(headers, "given_name")
        }
      }
      |> wrap_response(200)
      |> Poison.encode!()

    ResponseDecoder.check_response(%HTTPoison.Response{body: data, status_code: 200})
  end

  defp data_is_invalid_resp do
    data =
      %{"is_valid" => false}
      |> wrap_response(422)
      |> Poison.encode!()

    ResponseDecoder.check_response(%HTTPoison.Response{body: data, status_code: 422})
  end

  def extract_edrpou({:ok, %{"data" => %{"signer" => %{"edrpou" => edrpou}}}}) do
    edrpou
  end

  def extract_edrpou({:ok, _}), do: {:error, "signer.edrpou is missed in decoded digital signature"}
  def extract_edrpou(err), do: err

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
