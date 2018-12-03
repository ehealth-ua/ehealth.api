defmodule GraphQLWeb.Middleware.FilterArgument do
  @moduledoc """
  This middleware prepares the `filter` argument on connection fields as condition for `Ecto.Query.where/2`
  """

  @behaviour Absinthe.Middleware

  @filter_arg :filter

  def call(%{state: :unresolved, arguments: arguments} = resolution, _) do
    filter =
      arguments
      |> Map.get(@filter_arg, %{})
      |> Map.to_list()

    arguments = Map.put(arguments, @filter_arg, filter)

    %{resolution | arguments: arguments}
  end

  def call(resolution, _), do: resolution
end
