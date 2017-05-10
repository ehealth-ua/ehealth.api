defmodule EHealth.OAuth.API do
  @moduledoc """
  OAuth service layer
  """

  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias EHealth.API.Mithril

  require Logger

  @doc """
  Creates a new Mithril client for MSP after successfully created a new Legal Entity
  """
  def create_client({:ok, entity}, redirect_uri, headers) do
    client = %{
      "name" => generate_client_name(entity),
      "redirect_uri" => redirect_uri,
      "user_id" => get_consumer_id(headers),
    }

    client
    |> Mithril.create_client()
    |> put_security(entity)
  end
  def create_client(err, _redirect_uri, _headers), do: err

  def search_client({:ok, entity}, headers) do
    entity
    |> generate_client_name()
    |> Mithril.get_client_by_name(headers)
    |> put_security(entity)
  end
  def search_client(err, _headers), do: err

  @doc """
  Fetch Mithril credentials from Mithril.create_client respone
  """
  def put_security({:ok, %{"data" => data}}, entity) when is_list(data) do
    data =
      case length(data) > 0 do
        true -> List.first(data)
        false -> %{}
      end

    put_security({:ok, %{"data" => data}}, entity)
  end

  def put_security({:ok, %{"data" => data}}, entity) do
    {:ok, entity, %{
      "client_id" => Map.get(data, "id"),
      "client_secret" => Map.get(data, "secret"),
      "redirect_uri" => Map.get(data, "redirect_uri")
    }}
  end

  def put_security({:error, response}, %{"data" => %{"id" => id}} = entity) do
    Logger.error(fn -> "Cannot create or find Mithril client for Legal Entity #{id} Response: #{inspect response}" end)

    {:ok, entity, nil}
  end

  def generate_client_name(%{"data" => entity}) do
    Map.fetch!(entity, "short_name") <> "-" <> Map.fetch!(entity, "id")
  end

end
