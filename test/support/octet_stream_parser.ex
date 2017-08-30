defmodule Plug.Parsers.OCTETSTREAM do
  @moduledoc """
  Parses octet-stream request body.
  """

  @behaviour Plug.Parsers
  alias Plug.Conn

  def parse(conn, "application", "octet-stream", _headers, opts) do
      case Conn.read_body(conn, opts) do
        {:ok, body, conn} ->
          {:ok, %{content: body}, conn}
        {:more, _data, conn} ->
          {:error, :too_large, conn}
        {:error, :timeout} ->
          raise Plug.TimeoutError
        {:error, _} ->
          raise Plug.BadRequestError
      end
  end

  def parse(conn, _type, _subtype, _headers, _opts) do
    {:next, conn}
  end
end
