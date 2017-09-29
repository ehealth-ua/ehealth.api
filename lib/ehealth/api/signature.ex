defmodule EHealth.API.Signature do
  @moduledoc """
  Signature validator and data mapper
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  alias EHealth.API.ResponseDecoder
  import EHealth.Utils.Connection, only: [get_header: 2]

  @conn_timeouts [connect_timeout: 30_000, recv_timeout: 30_000, timeout: 30_000]

  def process_url(url), do: config()[:endpoint] <> url

  def decode_and_validate(signed_content, signed_content_encoding, headers) do
    if config()[:enabled] do
      params = %{
        "signed_content" => signed_content,
        "signed_content_encoding" => signed_content_encoding
      }

      "/digital_signatures"
      |> post!(Poison.encode!(params), headers, @conn_timeouts)
      |> ResponseDecoder.check_response()
    else
      data = Base.decode64(signed_content)
      case data do
        :error ->
          data =
            %{"is_valid" => false}
            |> wrap_response(422)
            |> Poison.encode!
         ResponseDecoder.check_response(%HTTPoison.Response{body: data, status_code: 422})
        {:ok, data} ->
          data =
            %{
              "content" => Poison.decode!(data),
              "is_valid" => true,
              "signer" => %{
                "edrpou" => get_header(headers, "edrpou"),
                "drfo" => get_header(headers, "drfo")
              }
            }
            |> wrap_response(200)
            |> Poison.encode!
          ResponseDecoder.check_response(%HTTPoison.Response{body: data, status_code: 200})
      end
    end
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
