defmodule EHealth.Utils.Connection do
  @moduledoc """
  Plug.Conn helpers
  """
  require Logger

  @header_consumer_id "x-consumer-id"
  @header_consumer_metadata "x-consumer-metadata"

  import Plug.Conn, only: [assign: 3, put_status: 2, halt: 1, get_req_header: 2]
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
    |> Poison.decode()
    |> process_decoded_data()
  end

  defp process_decoded_data({:ok, data}), do: Map.get(data, "client_id")
  defp process_decoded_data(_error), do: nil

  def get_header(headers, header) when is_list(headers) do
    list = for {k, v} <- headers, k == header, do: v
    List.first(list)
  end

  # plugs

  def header_required(%Plug.Conn{} = conn, header) do
    case get_req_header(conn, header) do
      [] ->
        conn
        |> put_status(:unauthorized)
        |> render(EView.Views.Error, :"401", %{
          message: "Missing header #{header}",
          invalid: [%{
            entry_type: :header,
            entry: header
          }]
        })
        |> halt()
      [_value | _] -> conn
    end
  end

  def client_id_exists(%Plug.Conn{req_headers: req_headers} = conn, _) do
    req_headers
    |> get_client_id()
    |> validate_client_id_existence(conn)
  end

  defp validate_client_id_existence(nil, conn) do
    conn
    |> put_status(:unauthorized)
    |> render(EView.Views.Error, :"401", %{
      message: "Misssing Client ID",
      invalid: [%{
        entry_type: :header,
        entry: @header_consumer_metadata
      }]
    })
    |> halt()
  end
  defp validate_client_id_existence(_client_id, conn), do: conn
end
