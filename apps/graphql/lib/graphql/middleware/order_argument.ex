defmodule GraphQL.Middleware.OrderByArgument do
  @moduledoc """
  This middleware prepares the `order_by` argument on connection fields as condition for `Ecto.Query.order_by/2`
  """
  @order_by_regex ~r/(\w+)_(asc|desc)$/

  @behaviour Absinthe.Middleware
  defmacro __using__(opts \\ []) do
    order_by_arg = Keyword.get(opts, :order_by_arg, :order_by)

    quote do
      def middleware(middleware, field, object) do
        middleware = super(middleware, field, object)
        type = field.type |> Absinthe.Type.unwrap() |> __MODULE__.__absinthe_type__()

        case {field, type} do
          {
            %{args: %{unquote(order_by_arg) => %Absinthe.Type.Argument{}}},
            %Absinthe.Type.Object{__private__: [{Absinthe.Relay, _}]}
          } ->
            opts = [order_by_arg: unquote(order_by_arg)]
            [{unquote(__MODULE__), opts} | middleware]

          _ ->
            middleware
        end
      end

      defoverridable middleware: 3
    end
  end

  def call(%{state: :unresolved, arguments: arguments} = resolution, order_by_arg: order_by_arg) do
    order =
      with {:ok, order_by} <- Map.fetch(arguments, order_by_arg),
           order_by <- Atom.to_string(order_by),
           [field, direction] <- Regex.run(@order_by_regex, order_by, capture: :all_but_first) do
        [{String.to_atom(direction), String.to_atom(field)}]
      else
        _ -> []
      end

    arguments = Map.put(arguments, order_by_arg, order)
    %{resolution | arguments: arguments}
  end

  def call(resolution, _), do: resolution
end
