defmodule EHealth.API.ResponseDecoder do

  @moduledoc """
  HTTPPoison JSON to Elixir data decoder and formatter
  """

  @sucess_codes [200, 201]

  def check_response(%HTTPoison.Response{status_code: status_code, body: body}) when status_code in @sucess_codes do
    decode_response(body)
  end

  def check_response(%HTTPoison.Response{body: body}) do
    body
    |> decode_response()
    |> map_response(:error)
  end

  def map_response({:ok, body}, type), do: {type, body}
  def map_response({:error, body}, type), do: {type, body}

  def decode_response(response) do
    case Poison.decode(response) do
       {:ok, body} -> {:ok, body}
       _           -> {:error, response}
     end
  end
end
