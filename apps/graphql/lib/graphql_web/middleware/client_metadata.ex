defmodule GraphQLWeb.Middleware.ClientMetadata do
  @moduledoc """
  This middleware puts the client metadata to context.
  """

  @behaviour Absinthe.Middleware

  import Core.API.Helpers.Connection, only: [get_client_id: 1]
  import GraphQLWeb.Resolvers.Helpers.Errors, only: [format_unauthenticated_error: 0]

  alias Absinthe.{Resolution, Type}

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]

  defmacro __using__(opts \\ []) do
    meta_key = Keyword.get(opts, :meta_key, :client_metadata)
    headers_key = Keyword.get(opts, :headers_key, :headers)
    client_id_key = Keyword.get(opts, :client_id_key, :client_id)
    client_type_key = Keyword.get(opts, :client_type_key, :client_type)

    quote do
      def middleware(middleware, field, object) do
        middleware = super(middleware, field, object)

        case Type.meta(field) do
          %{unquote(meta_key) => _} ->
            opts = [
              meta_key: unquote(meta_key),
              headers_key: unquote(headers_key),
              client_id_key: unquote(client_id_key),
              client_type_key: unquote(client_type_key)
            ]

            [{unquote(__MODULE__), opts} | middleware]

          _ ->
            middleware
        end
      end

      defoverridable middleware: 3
    end
  end

  def call(%{state: :unresolved, context: context} = resolution, opts) do
    meta_key = Keyword.get(opts, :meta_key)
    headers_key = Keyword.get(opts, :headers_key)

    required_metadata = Type.meta(resolution.definition.schema_node, meta_key)

    with {:ok, headers} <- Map.fetch(context, headers_key),
         client_id <- get_client_id(headers),
         {:ok, metadata} <- get_metadata(required_metadata, client_id, headers, opts) do
      %{resolution | context: Map.merge(context, metadata)}
    else
      _ -> Resolution.put_result(resolution, {:error, format_unauthenticated_error()})
    end
  end

  def call(resolution, _), do: resolution

  defp get_metadata(required_metadata, client_id, headers, opts) do
    client_id_key = Keyword.get(opts, :client_id_key)
    client_type_key = Keyword.get(opts, :client_type_key)

    Enum.reduce_while(required_metadata, {:ok, %{}}, fn
      ^client_id_key, {:ok, acc} ->
        {:cont, {:ok, Map.put(acc, client_id_key, client_id)}}

      ^client_type_key, {:ok, acc} ->
        with {:ok, client_type} <- @mithril_api.get_client_type_name(client_id, headers) do
          {:cont, {:ok, Map.put(acc, client_type_key, client_type)}}
        else
          error -> {:halt, error}
        end

      _, acc ->
        {:cont, acc}
    end)
  end
end
