defmodule GraphQLWeb.Middleware.FilterArgument do
  @moduledoc """
  This middleware prepares the `filter` argument on connection fields as condition for `Ecto.Query.where/2`
  """

  @behaviour Absinthe.Middleware

  defmacro __using__(opts \\ []) do
    filter_arg = Keyword.get(opts, :filter_arg, :filter)

    quote do
      def middleware(middleware, field, object) do
        middleware = super(middleware, field, object)
        type = field.type |> Absinthe.Type.unwrap() |> __MODULE__.__absinthe_type__()

        case {field, type} do
          {
            %{args: %{unquote(filter_arg) => %Absinthe.Type.Argument{}}},
            %Absinthe.Type.Object{__private__: [{Absinthe.Relay, _}]}
          } ->
            opts = [filter_arg: unquote(filter_arg)]
            [{unquote(__MODULE__), opts} | middleware]

          _ ->
            middleware
        end
      end

      defoverridable middleware: 3
    end
  end

  def call(%{state: :unresolved, arguments: arguments} = resolution, filter_arg: filter_arg) do
    filter =
      arguments
      |> Map.get(filter_arg, %{})
      |> Map.to_list()

    arguments = Map.put(arguments, filter_arg, filter)

    %{resolution | arguments: arguments}
  end

  def call(res, _), do: res
end
