defmodule EHealth.Utils.Connection do
  @moduledoc """
  Plug.Conn helpers
  """

  import Plug.Conn, only: [assign: 3, put_status: 2, halt: 1]
  import Phoenix.Controller, only: [render: 4]

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
    get_header(headers, "x-consumer-id")
  end

  def get_client_id(headers) when is_list(headers) do
    headers
    |> get_client_metadata()
    |> process_client_metadata()
  end

  def get_client_metadata(headers) when is_list(headers) do
    get_header(headers, "x-consumer-metadata")
  end

  defp process_client_metadata(nil), do: nil
  defp process_client_metadata(metadata) do
    metadata
    |> Base.decode64()
    |> json_decode()
    |> process_decoded_data()
  end

  defp json_decode({:ok, data}), do: Poison.decode(data)
  defp json_decode(_error), do: nil

  defp process_decoded_data({:ok, data}), do: Map.get(data, "client_id")
  defp process_decoded_data(_error), do: nil

  def get_header(headers, header) when is_list(headers) do
    list = for {k, v} <- headers, k == header, do: v
    List.first(list)
  end

  def header_required(%Plug.Conn{req_headers: req_headers} = conn, header) do
    req_headers
    |> get_header(header)
    |> validate_header_existance(header, conn)
  end

  defp validate_header_existance(nil, header_key, conn) do
    conn
    |> put_status(:unauthorized)
    |> render(EView.Views.Error, :"401", %{
      message: "Missing header #{header_key}",
      invalid: [%{
        entry_type: :header,
        entry: header_key
      }]
    })
    |> halt()
  end
  defp validate_header_existance(_header_value, _header_key, conn), do: conn
end
