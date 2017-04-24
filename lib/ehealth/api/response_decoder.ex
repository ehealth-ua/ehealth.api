defmodule EHealth.API.ResponseDecoder do

  @moduledoc """
  HTTPPoison JSON to Elixir data decoder and formatter
  """

  def check_response(%HTTPoison.Response{status_code: 200, body: body}), do: body |> decode_response()
  def check_response(%HTTPoison.Response{body: body}), do: body |> decode_response() |> map_response(:error)

  def map_response({:ok, body}, type), do: {type, body}
  def map_response({:error, body}, type), do: {type, body}

  def decode_response(response) do
    case Poison.decode(response) do
       {:ok, body} -> {:ok, body}
       _           -> {:error, response}
     end
  end
end
