defmodule GraphQLWeb.Plugs.Context do
  @moduledoc """
  This plug builds the document execution context.
  """

  @behaviour Plug

  import Plug.Conn, only: [get_req_header: 2]
  import Absinthe.Plug, only: [put_options: 2]

  def init(opts), do: opts

  def call(conn, opts) do
    context = build_context(conn, opts)
    put_options(conn, context: context)
  end

  def build_context(conn, opts) do
    [&build_headers/2, &build_scope/2]
    |> Enum.flat_map(& &1.(conn, opts))
    |> Enum.into(%{})
  end

  defp build_headers(%{req_headers: headers}, _), do: [headers: headers]

  defp build_scope(conn, opts) do
    header = Keyword.get(opts, :scope_header)
    context_key = Keyword.get(opts, :scope_context_key, :scope)

    case get_req_header(conn, header) do
      [scope] ->
        [{context_key, String.split(scope)}]

      _ ->
        []
    end
  end
end
