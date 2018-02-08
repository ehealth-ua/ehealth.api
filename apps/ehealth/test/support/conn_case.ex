defmodule EHealth.Web.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build and query models.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """
  use ExUnit.CaseTemplate

  @client_id "d290f1ee-6c54-4b01-90e6-d701748f0851"
  @header_consumer_id "x-consumer-id"
  @header_consumer_meta "x-consumer-metadata"

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      import EHealth.Web.ConnCase
      import EHealthWeb.Router.Helpers
      import EHealth.Test.Support.Fixtures
      import EHealth.Factories

      # The default endpoint for testing
      @endpoint EHealth.Web.Endpoint
    end
  end

  setup tags do
    _ = tags

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EHealth.Repo)
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EHealth.PRMRepo)
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EHealth.EventManagerRepo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(EHealth.Repo, {:shared, self()})
      Ecto.Adapters.SQL.Sandbox.mode(EHealth.PRMRepo, {:shared, self()})
      Ecto.Adapters.SQL.Sandbox.mode(EHealth.EventManagerRepo, {:shared, self()})
    end

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> put_consumer_id_header()
      |> put_client_id(tags[:with_client_id])

    {:ok, conn: conn}
  end

  def consumer_id_header, do: @header_consumer_id

  defp put_client_id(conn, true), do: put_client_id_header(conn)
  defp put_client_id(conn, _), do: conn

  def put_client_id_header(conn, id \\ @client_id) do
    data = Poison.encode!(%{"client_id" => id})

    Plug.Conn.put_req_header(conn, @header_consumer_meta, data)
  end

  def put_consumer_id_header(conn, id \\ Ecto.UUID.generate()) do
    Plug.Conn.put_req_header(conn, @header_consumer_id, id)
  end

  def delete_consumer_id_header(conn) do
    Plug.Conn.delete_req_header(conn, @header_consumer_id)
  end

  def delete_client_id_header(conn) do
    Plug.Conn.delete_req_header(conn, @header_consumer_meta)
  end

  def start_microservices(module) do
    {:ok, port} = :gen_tcp.listen(0, [])
    {:ok, port_string} = :inet.port(port)
    :erlang.port_close(port)
    ref = make_ref()
    # TODO: only 1 worker here
    {:ok, _pid} = Plug.Adapters.Cowboy.http(module, [], port: port_string, ref: ref)
    {:ok, port_string, ref}
  end

  def stop_microservices(ref) do
    Plug.Adapters.Cowboy.shutdown(ref)
  end

  def convert_atom_keys_to_strings(map) when is_map(map) do
    Enum.reduce(map, Map.new(), fn {key, value}, acc -> Map.put(acc, to_string(key), value) end)
  end

  def convert_atom_keys_to_strings(map) do
    map
  end

  def get_headers_with_consumer_id do
    [
      {"x-consumer-id", Ecto.UUID.generate()}
    ]
  end

  def assert_show_response_schema(response, type) when is_binary(type) do
    assert_json_schema(response, "specs/json_schemas/#{type}/#{type}_show_response.json")
  end

  def assert_list_response_schema(response, type) when is_binary(type) do
    assert_json_schema(response, "specs/json_schemas/#{type}/#{type}_list_response.json")
  end

  def assert_json_schema(data, schema_path) do
    assert :ok ==
             schema_path
             |> File.read!()
             |> Poison.decode!()
             |> NExJsonSchema.Validator.validate(data)

    data
  end
end
