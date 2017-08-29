defmodule EHealth.PRM.GlobalParameters do
  @moduledoc """
  The boundary for the Global parameters system.
  """

  import Ecto.Query
  import Ecto.Changeset

  alias EHealth.PRMRepo
  alias EHealth.PRM.GlobalParameters.Schema, as: GlobalParameter

  def list_global_parameters do
    query = from gp in GlobalParameter,
      order_by: [desc: :inserted_at]

    PRMRepo.all(query)
  end

  def get_values do
    for p <- list_global_parameters(), into: %{}, do: {p.parameter, p.value}
  end

  def create_or_update_global_parameters(params, client_id) do
    result =
      params
      |> Map.keys()
      |> Enum.reduce_while(nil, fn(x, _acc) -> process_global_parameters(x, params, client_id) end)

    case result do
      nil -> {:ok, list_global_parameters()}
      error -> error
    end
  end

  defp create_or_update_global_parameters(key, value, client_id) do
    case PRMRepo.get_by(GlobalParameter, parameter: key) do
      %GlobalParameter{} = global_parameter ->
        update_global_parameter(global_parameter, %{
          value: value,
          updated_by: client_id
        }, client_id)
      nil ->
        create_global_parameter(%{
          parameter: key,
          value: value,
          inserted_by: client_id,
          updated_by: client_id
        }, client_id)
    end
  end

  defp process_global_parameters(x, params, client_id) do
    case create_or_update_global_parameters(x, Map.get(params, x), client_id) do
      {:ok, _} -> {:cont, nil}
      {:error, _} = error -> {:halt, error}
    end
  end

  def create_global_parameter(attrs, user_id) do
    %GlobalParameter{}
    |> global_parameter_changeset(attrs)
    |> PRMRepo.insert_and_log(user_id)
  end

  def update_global_parameter(%GlobalParameter{} = global_parameter, attrs, user_id) do
    global_parameter
    |> global_parameter_changeset(attrs)
    |> PRMRepo.update_and_log(user_id)
  end

  defp global_parameter_changeset(%GlobalParameter{} = global_paramter, attrs) do
    fields = ~W(
      parameter
      value
      inserted_by
      updated_by
    )a

    global_paramter
    |> cast(attrs, fields)
    |> validate_required(fields)
  end
end
