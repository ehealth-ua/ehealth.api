defmodule Core.Rpc do
  @moduledoc """
  This module contains functions that are called from other pods via RPC.
  """

  alias Core.Employees.Employee
  alias Core.Parties
  alias Core.Parties.Party
  import Ecto.Query

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  @doc """
  Get employee ids by user id

  ## Examples

      iex> Core.Rpc.employees_by_user_id_client_id(
        "26e673e1-1d68-413e-b96c-407b45d9f572",
        "d221d7f1-81cb-44d3-b6d4-8d7e42f97ff9"
      )
      {:ok, ["1241d1f9-ae81-4fe5-b614-f4f780a5acf0"]}
  """
  @spec employees_by_user_id_client_id(user_id :: binary(), client_id :: binary()) :: nil | {:ok, list()}
  def employees_by_user_id_client_id(user_id, client_id) do
    with %Party{id: party_id} <- Parties.get_by_user_id(user_id) do
      {:ok, employees_by_party_id_client_id(party_id, client_id)}
    else
      _ -> nil
    end
  end

  def employees_by_party_id_client_id(party_id, client_id) do
    Employee
    |> select([e], e.id)
    |> where([e], e.party_id == ^party_id)
    |> where([e], e.legal_entity_id == ^client_id)
    |> where([e], e.status == ^Employee.status(:approved))
    |> @read_prm_repo.all()
  end

  def tax_id_by_employee_id(employee_id) do
    Party
    |> select([p], p.tax_id)
    |> join(:left, [p], e in Employee, on: p.id == e.party_id)
    |> where([p, e], e.id == ^employee_id)
    |> @read_prm_repo.one()
  end

  def employee_by_id(employee_id) do
    Employee
    |> where([e], e.id == ^employee_id)
    |> preload([e], :party)
    |> @read_prm_repo.one()
  end
end
