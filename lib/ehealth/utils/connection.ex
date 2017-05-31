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
end
