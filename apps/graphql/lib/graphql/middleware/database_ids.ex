defmodule GraphQL.Middleware.DatabaseIDs do
  @moduledoc """
  This middleware reassigns internal IDs in objects that are implementing Node interface.
  """

  @behaviour Absinthe.Middleware

  alias Absinthe.Resolution

  defmacro __using__(opts \\ []) do
    inner_key = Keyword.get(opts, :inner_key, :id)
    outer_key = Keyword.get(opts, :outer_key, :database_id)

    quote do
      def middleware(middleware, %{identifier: unquote(outer_key)} = field, object) do
        opts = [inner_key: unquote(inner_key)]
        super(middleware, field, object) ++ [{unquote(__MODULE__), opts}]
      end

      def middleware(middleware, field, object), do: super(middleware, field, object)

      defoverridable middleware: 3
    end
  end

  def call(%{state: :resolved, source: source} = resolution, inner_key: inner_key) do
    value = Map.get(source, inner_key)

    Resolution.put_result(resolution, {:ok, value})
  end

  def call(resolution, _), do: resolution
end
