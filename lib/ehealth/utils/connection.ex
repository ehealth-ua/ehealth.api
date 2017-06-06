defmodule EHealth.Utils.Connection do
  @moduledoc """
  Plug.Conn helpers
  """

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

  def get_consumer_id(headers) when is_list(headers) do
    list = for {k, v} <- headers, k == "x-consumer-id", do: v
    List.first(list)
  end

  def get_client_metadata(headers) when is_list(headers) do
    list = for {k, v} <- headers, k == "x-consumer-metadata", do: v
    List.first(list)
  end

  def get_client_id(headers) when is_list(headers) do
    headers
    |> get_client_metadata()
    |> process_client_metadata()
  end

  defp process_client_metadata(nil), do: nil
  defp process_client_metadata(metadata) do
    metadata
    |> Poison.decode()
    |> process_decoded_data()
  end

  defp process_decoded_data({:ok, data}), do: Map.get(data, "client_id")
  defp process_decoded_data(_error), do: nil
end
