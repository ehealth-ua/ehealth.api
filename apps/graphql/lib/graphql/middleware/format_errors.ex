defmodule GraphQL.Middleware.FormatErrors do
  @moduledoc """
  Transforms internal error formats into external GraphQL error format.
  """

  @behaviour Absinthe.Middleware

  alias GraphQL.Helpers.Errors

  defmacro __using__(_) do
    quote do
      def middleware(middleware, field, object) do
        super(middleware, field, object) ++ [unquote(__MODULE__)]
      end

      defoverridable middleware: 3
    end
  end

  def call(%{state: :resolved, errors: errors} = resolution, _) do
    %{resolution | errors: Enum.map(errors, &Errors.format/1)}
  end

  def call(resolution, _), do: resolution
end
