defmodule Core.Expectations.Mithril do
  @moduledoc false

  import Mox

  def mis(n \\ 1), do: get_client_type_name("MIS", n)
  def nhs(n \\ 1), do: get_client_type_name("NHS", n)
  def msp(n \\ 1), do: get_client_type_name("MSP", n)
  def cabinet(n \\ 1), do: get_client_type_name("CABINET", n)
  defdelegate admin(n \\ 1), to: __MODULE__, as: :nhs

  defp get_client_type_name(type, n) do
    expect(MithrilMock, :get_client_type_name, n, fn _, _ -> {:ok, type} end)
  end

  def get_client(n \\ 1) do
    expect(MithrilMock, :get_client, n, fn id, _ ->
      {:ok,
       %{
         "data" => %{
           "id" => id,
           "name" => "test",
           "type" => "client",
           "redirect_uri" => "http://example.com/redirect_uri"
         }
       }}
    end)
  end

  def put_client(n \\ 1) do
    expect(MithrilMock, :put_client, n, fn params, _ ->
      {:ok, %{"data" => params}}
    end)
  end

  def upsert_client_connection(n \\ 1) do
    expect(MithrilMock, :upsert_client_connection, n, fn client_id, params, _ ->
      default = %{
        "client_id" => client_id,
        "redirect_uri" => "https://example.com",
        "secret" => "secret"
      }

      {:ok, %{"data" => Map.merge(default, params)}}
    end)
  end

  def get_client_connections(n \\ 1) do
    expect(MithrilMock, :get_client_connections, n, fn client_id, _params, _ ->
      connection = %{
        "client_id" => client_id,
        "redirect_uri" => "https://example.com",
        "secret" => "secret"
      }

      {:ok, %{"data" => [connection]}}
    end)
  end

  def get_user(n \\ 1) do
    expect(MithrilMock, :get_user_by_id, n, fn id, _ ->
      {:ok,
       %{
         "data" => %{
           "id" => id,
           "email" => "mis_bot_1493831618@user.com",
           "type" => "user"
         }
       }}
    end)
  end
end
