defmodule Core.MedicationRequestRequest.Operation do
  @moduledoc false
  @enforce_keys [:changeset]

  defstruct [:changeset, :data, :valid?]

  alias Core.MedicationRequestRequest.Operation

  def new(%Ecto.Changeset{} = changeset) do
    %Operation{changeset: changeset, data: %{}, valid?: true}
  end

  def changeset(%Operation{} = operation) do
    operation.changeset
  end

  def add_data(%Operation{} = operation, key, map) when is_map(map) or is_list(map) or is_nil(map) do
    Map.put(operation, :data, Map.put(operation.data, key, map))
  end

  def add_data(%Operation{} = operation, key, fun, args) when is_function(fun) when is_list(args) do
    Map.put(operation, :data, Map.put(operation.data, key, apply(fun, [operation] ++ args)))
  end

  def call_changeset(%Operation{} = operation, function, args) do
    {_, operation} =
      Map.get_and_update(operation, :changeset, fn changeset -> {:ok, apply(function, [changeset] ++ args)} end)

    operation
  end
end
