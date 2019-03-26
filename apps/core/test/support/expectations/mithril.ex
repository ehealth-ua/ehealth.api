defmodule Core.Expectations.Mithril do
  @moduledoc false

  import Mox

  alias Ecto.UUID

  def mis(n \\ 1), do: get_client_type_name("MIS", n)
  def nhs(n \\ 1), do: get_client_type_name("NHS", n)
  def msp(n \\ 1), do: get_client_type_name("MSP", n)
  def msp_pharmacy(n \\ 1), do: get_client_type_name("MSP_PHARMACY", n)
  def pharmacy(n \\ 1), do: get_client_type_name("PHARMACY", n)
  def cabinet(n \\ 1), do: get_client_type_name("CABINET", n)
  defdelegate admin(n \\ 1), to: __MODULE__, as: :nhs

  def get_client_type_name(type, n \\ 1) do
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

  def deactivate_client_tokens(n \\ 1) do
    expect(MithrilMock, :deactivate_client_tokens, n, fn client_id, _headers ->
      client = %{
        "id" => client_id,
        "name" => "test",
        "type" => "client"
      }

      {:ok, %{"data" => client}}
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

  def get_roles_by_name(n \\ 1, id \\ UUID.generate()) do
    expect(MithrilMock, :get_roles_by_name, n, fn _, _ ->
      {:ok, %{"data" => [%{"id" => id}]}}
    end)
  end

  def get_user_roles(n \\ 1) do
    expect(MithrilMock, :get_user_roles, n, fn _, _, _ ->
      {:ok, %{"data" => []}}
    end)
  end

  def create_user_role(n \\ 1) do
    expect(MithrilMock, :create_user_role, n, fn _, _, _ ->
      {:ok, %{"data" => %{}}}
    end)
  end

  def get_client_type_by_name(n \\ 1, id \\ UUID.generate()) do
    expect(MithrilMock, :get_client_type_by_name, n, fn _, _ ->
      {:ok, %{"data" => [%{"id" => id}]}}
    end)
  end

  def delete_user_roles_by_user_and_role_name(n \\ 1, id \\ UUID.generate()) do
    expect(MithrilMock, :delete_user_roles_by_user_and_role_name, n, fn _, _, _ ->
      {:ok, %{"data" => [%{"id" => id}]}}
    end)
  end

  def delete_apps_by_user_and_client(n \\ 1, id \\ UUID.generate()) do
    expect(MithrilMock, :delete_apps_by_user_and_client, n, fn _, _, _ ->
      {:ok, %{"data" => [%{"id" => id}]}}
    end)
  end

  def delete_tokens_by_user_and_client(n \\ 1, id \\ UUID.generate()) do
    expect(MithrilMock, :delete_tokens_by_user_and_client, n, fn _, _, _ ->
      {:ok, %{"data" => [%{"id" => id}]}}
    end)
  end

  def search_user_roles(role_name, n \\ 1) do
    expect(MithrilMock, :search_user_roles, n, fn _, _ ->
      {:ok, %{"data" => [%{"role_name" => role_name}]}}
    end)
  end
end
