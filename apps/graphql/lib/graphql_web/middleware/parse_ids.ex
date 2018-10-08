defmodule GraphQLWeb.Middleware.ParseIDs do
  @moduledoc """
  This middleware turns global IDs into internal IDs in objects that are implementing Node interface.
  """

  defmacro __using__(opts \\ []) do
    global_id_arg = Keyword.get(opts, :global_id_arg, :id)

    quote do
      def middleware(middleware, field, object) do
        middleware = super(middleware, field, object)
        type = field.type |> Absinthe.Type.unwrap() |> __MODULE__.__absinthe_type__()

        case type do
          %{interfaces: [:node], identifier: identifier} ->
            opts = [{unquote(global_id_arg), identifier}]
            [{Absinthe.Relay.Node.ParseIDs, opts} | middleware]

          _ ->
            middleware
        end
      end

      defoverridable middleware: 3
    end
  end
end
