defmodule GraphQLWeb.Middleware.TransformInput do
  @moduledoc """
  Helps to restruct data from filter's input
  This can be used as:

      middleware(TransformInput, %{
        :authentication_methods => [:personal, :authentication_method, :phone_number]
      })
  """

  @behaviour Absinthe.Middleware

  def call(resolution, rules \\ [])

  def call(%{state: :unresolved, arguments: arguments} = resolution, rules) do
    # TODO: Add ability to transform input params structure (not only filter)
    filter = Map.get(arguments, :filter, %{})

    filter =
      Enum.reduce(rules, %{}, fn {key, value_path}, acc ->
        field_value = get_in(filter, value_path)
        put_value(key, field_value, acc)
      end)

    %{resolution | arguments: Map.put(arguments, :filter, filter)}
  end

  def call(resolution, _), do: resolution

  defp put_value(_, nil, acc), do: acc

  defp put_value(key_path, value, acc) when is_list(key_path) do
    Map.merge(acc, put_in(%{}, Enum.map(key_path, &Access.key(&1, %{})), value))
  end

  defp put_value(key, value, acc), do: Map.put(acc, key, value)
end
