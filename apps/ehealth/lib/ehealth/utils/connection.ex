defmodule EHealth.Utils.Connection do
  @moduledoc """
  Plug.Conn helpers
  """
  require Logger

  @header_consumer_id "x-consumer-id"
  @header_consumer_metadata "x-consumer-metadata"

  import Plug.Conn, only: [assign: 3]

  def assign_security(conn, security) when is_map(security) do
    assign_urgent(conn, "security", security)
  end

  def assign_security(conn, _), do: conn

  def assign_urgent(%Plug.Conn{assigns: %{urgent: urgent}} = conn, key, value) do
    assign(conn, :urgent, Map.put(urgent, key, value))
  end

  def assign_urgent(conn, key, value) do
    assign(conn, :urgent, %{key => value})
  end

  def get_consumer_id(headers) do
    get_header(headers, @header_consumer_id)
  end

  def get_client_id(headers) do
    headers
    |> get_client_metadata()
    |> decode_client_metadata()
  end

  def get_client_metadata(headers) do
    get_header(headers, @header_consumer_metadata)
  end

  defp decode_client_metadata(nil), do: nil

  defp decode_client_metadata(metadata) do
    metadata
    |> Jason.decode()
    |> process_decoded_data()
  end

  defp process_decoded_data({:ok, data}), do: Map.get(data, "client_id")
  defp process_decoded_data(_error), do: nil

  def get_header(headers, header) when is_list(headers) do
    case List.keyfind(headers, header, 0) do
      nil -> nil
      {_key, val} -> val
    end
  end

  def get_header_name(:header_consumer_metadata), do: @header_consumer_metadata
end
