defmodule GraphQLWeb.Middleware.DatabaseIDs do
  @moduledoc """
  This middleware reassigns internal IDs in objects that are implementing Node interface.
  """

  @behaviour Absinthe.Middleware

  alias Absinthe.Resolution

  defmacro __using__(opts \\ []) do
    inner_key = Keyword.get(opts, :inner_key, :id)
    outer_key = Keyword.get(opts, :outer_key, :database_id)

    quote do
      def middleware(middleware, field, object) do
        middleware = super(middleware, field, object)
        type = field.type |> Absinthe.Type.unwrap() |> __MODULE__.__absinthe_type__()

        case type do
          %{interfaces: [:node]} ->
            opts = [inner_key: unquote(inner_key), outer_key: unquote(outer_key)]
            middleware ++ [{unquote(__MODULE__), opts}]

          _ ->
            middleware
        end
      end

      defoverridable middleware: 3
    end
  end

  def call(%{state: :resolved} = resolution, opts) do
    inner_key = Keyword.get(opts, :inner_key)
    outer_key = Keyword.get(opts, :outer_key)

    inner_id = Map.get(resolution.value, inner_key)
    value = Map.put(resolution.value, outer_key, inner_id)

    Resolution.put_result(resolution, {:ok, value})
  end

  def call(res, _), do: res
end
