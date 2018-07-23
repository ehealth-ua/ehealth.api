defmodule EHealth.ValidationError do
  @moduledoc """
  Error struct and processing
  """

  @enforce_keys [:description, :path]
  defstruct description: nil, params: [], rule: :invalid, path: nil
end

defprotocol EHealth.Validators.Error do
  @doc "Dump error to tuple"
  def dump(error)
end

defimpl EHealth.Validators.Error, for: List do
  def dump(errors) do
    {:error,
     errors
     |> Enum.map(&EHealth.Validators.Error.dump/1)
     |> Enum.map(fn {_k, v} -> v end)
     |> Enum.flat_map(& &1)}
  end
end

defimpl EHealth.Validators.Error, for: EHealth.ValidationError do
  def dump(%{description: description, rule: rule, path: path, params: params}) do
    {:error,
     [
       {%{
          description: description,
          params: params,
          rule: rule
        }, path}
     ]}
  end
end

defimpl EHealth.Validators.Error, for: BitString do
  def dump(reason), do: {:error, {:"422", reason}}
end

defimpl EHealth.Validators.Error, for: Atom do
  def dump(_reason), do: :error
end
