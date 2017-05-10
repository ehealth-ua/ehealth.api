defmodule EHealth.Utils.Connection do
  @moduledoc """
  Plug.Conn helpers
  """

  import Plug.Conn, only: [assign: 3]

  def assign_security(conn, security) when is_map(security) do
    assign(conn, :urgent, %{"security" => security})
  end
  def assign_security(conn, _), do: conn

  def get_consumer_id(headers) when is_list(headers) do
    list = for {k, v} <- headers, k == "x-consumer-id", do: v
    List.first(list)
  end
end
