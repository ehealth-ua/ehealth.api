defmodule EHealth.Plugs.Headers do
  @moduledoc """
  Plug module for headers validation
  """
  use EHealth.Web, :plugs

  def header_required(%Plug.Conn{} = conn, header) do
    case get_req_header(conn, header) do
      [] ->
        conn
        |> put_status(:unauthorized)
        |> render(EView.Views.Error, :"401", %{
          message: "Missing header #{header}",
          invalid: [
            %{
              entry_type: :header,
              entry: header
            }
          ]
        })
        |> halt()

      _ ->
        conn
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
      invalid: [
        %{
          entry_type: :header,
          entry: get_header_name(:header_consumer_metadata)
        }
      ]
    })
    |> halt()
  end

  defp validate_client_id_existence(_client_id, conn), do: conn
end
