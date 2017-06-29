defmodule EHealth.Validators.RemoteForeignKey do
  @moduledoc false

  import Ecto.Changeset
  alias EHealth.API.PRM

  def validate(changeset, _, nil), do: changeset
  def validate(changeset, :legal_entity_id = key, id), do: validate(&PRM.get_legal_entity_by_id/1, changeset, key, id)
  def validate(changeset, :division_id = key, id), do: validate(&PRM.get_division_by_id/1, changeset, key, id)
  def validate(changeset, :employee_id = key, id), do: validate(&PRM.get_employee_by_id/1, changeset, key, id)

  defp validate(func, changeset, key, id) do
    id
    |> func.()
    |> process_resp(key, changeset)
  end

  defp process_resp({:ok, _}, _key, changeset), do: changeset
  defp process_resp({:error, _}, key, changeset), do: add_error(changeset, key, "does not exist")
end
