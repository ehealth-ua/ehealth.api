defmodule GraphQLWeb.Middleware.Filtering do
  @moduledoc false

  @behaviour Absinthe.Middleware

  def call(resolution, rules \\ [])

  def call(%{state: :unresolved, arguments: arguments} = resolution, rules) do
    filters =
      rules
      |> get_conditions(arguments)
      |> Enum.map(fn {field, nil, conditions} -> {field, conditions} end)
      |> Map.new()

    arguments = Map.merge(arguments, filters)

    %{resolution | arguments: arguments}
  end

  def call(resolution, _), do: resolution

  defp get_conditions([], _), do: []

  defp get_conditions([{field, rules} | tail], values) do
    value = Map.get(values, field)
    get_condition(field, rules, value) ++ get_conditions(tail, values)
  end

  defp get_condition(_, _, nil), do: []

  defp get_condition(field, rules, values) when is_list(rules) do
    [{field, nil, get_conditions(rules, values)}]
  end

  defp get_condition(field, operator, value) do
    [{field, operator, value}]
  end
end
