defmodule GraphQLWeb.Middleware.Filtering do
  @moduledoc false

  @behaviour Absinthe.Middleware

  @filter_argument :filter

  def call(resolution, rules \\ [])

  def call(%{state: :unresolved, arguments: arguments} = resolution, rules) do
    values = Map.get(arguments, @filter_argument)
    conditions = get_conditions(rules, values)
    arguments = Map.put(arguments, @filter_argument, conditions)

    %{resolution | arguments: arguments}
  end

  def call(resolution, _), do: resolution

  defp get_conditions([], _), do: []

  defp get_conditions(_, nil), do: []

  defp get_conditions([{field, rules} | tail], values) do
    value = Map.get(values, field)
    get_condition(field, rules, value) ++ get_conditions(tail, values)
  end

  defp get_condition(_, _, nil), do: []

  defp get_condition(field, rules, values) when is_list(rules) do
    [{field, nil, get_conditions(rules, values)}]
  end

  defp get_condition(:database_id, operator, value), do: get_condition(:id, operator, value)

  defp get_condition(field, operator, value) do
    [{field, operator, value}]
  end
end
