defmodule GraphQL.Helpers.LanguageConventions do
  @moduledoc """
  Functions for transforming data structures according to conventions established
  in Elixir and GraphQL.
  """

  alias Absinthe.Utils

  def to_external(%{} = term) do
    term
    |> Map.to_list()
    |> to_external()
    |> Map.new()
  end

  def to_external([head | tail]) when is_map(head) or is_list(head) or is_tuple(head) do
    [to_external(head) | to_external(tail)]
  end

  def to_external([head | tail]), do: [head | to_external(tail)]

  def to_external({key, value}) when is_map(value) or is_list(value) do
    {to_external(key), to_external(value)}
  end

  def to_external({key, value}), do: {to_external(key), value}

  def to_external(term) when is_atom(term) do
    term
    |> Atom.to_string()
    |> to_external()
  end

  def to_external(term) when is_binary(term), do: Utils.camelize(term, lower: true)

  def to_external(term), do: term

  # TODO: Add reverse transforms
end
