defmodule GraphQLWeb.Middleware.ClientAuthorization do
  @moduledoc """
  This middleware performs client type based authorization on the fields.
  """

  @behaviour Absinthe.Middleware

  alias Absinthe.{Resolution, Type}

  defmacro __using__(opts \\ []) do
    meta_key = Keyword.get(opts, :meta_key, :allowed_clients)
    context_key = Keyword.get(opts, :context_key, :client_type)

    quote do
      def middleware(middleware, field, object) do
        middleware = super(middleware, field, object)

        case Type.meta(field) do
          %{unquote(meta_key) => _} ->
            opts = [meta_key: unquote(meta_key), context_key: unquote(context_key)]
            [{unquote(__MODULE__), opts} | middleware]

          _ ->
            middleware
        end
      end

      defoverridable middleware: 3
    end
  end

  def call(%{state: :unresolved, context: context} = resolution, meta_key: meta_key, context_key: context_key) do
    allowed_clients = Type.meta(resolution.definition.schema_node, meta_key)
    current_client = Map.get(context, context_key)

    if current_client in allowed_clients do
      resolution
    else
      Resolution.put_result(resolution, {:error, :forbidden})
    end
  end

  def call(resolution, _), do: resolution
end
