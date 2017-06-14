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
      import Ehealth.Web.Router.Helpers
      import EHealth.Web.ConnCase

      # The default endpoint for testing
      @endpoint EHealth.Web.Endpoint
    end
  end

  setup tags do
    _ = tags

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EHealth.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(EHealth.Repo, {:shared, self()})
    end

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header(@header_consumer_id, Ecto.UUID.generate())
      |> put_client_id(tags[:with_client_id])

    {:ok, conn: conn}
  end

  defp put_client_id(conn, true), do: put_client_id_header(conn)
  defp put_client_id(conn, _), do: conn

  def put_client_id_header(conn, id \\ @client_id) do
    data = Poison.encode!(%{"client_id" => id})

    Plug.Conn.put_req_header(conn, @header_consumer_meta, data)
  end

  def delete_client_id_header(conn) do
    Plug.Conn.delete_req_header(conn, @header_consumer_meta)
  end
end
