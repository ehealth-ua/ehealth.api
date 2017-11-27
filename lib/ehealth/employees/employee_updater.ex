defmodule EHealth.Employees.EmployeeUpdater do
  @moduledoc false

  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias EHealth.API.OPS
  alias EHealth.API.Mithril
  alias EHealth.PartyUsers
  alias EHealth.Employees
  alias EHealth.Employees.Employee
  alias EHealth.PRMRepo
  import Ecto.Query

  require Logger

  @type_owner Employee.type(:owner)
  @type_pharmacy_owner Employee.type(:pharmacy_owner)

  @status_approved Employee.status(:approved)
  @status_dismissed Employee.status(:dismissed)

  def deactivate(%{"id" => id} = params, headers, with_owner \\ false) do
    legal_entity_id = Map.get(params, "legal_entity_id")
    with employee <- Employees.get_by_id!(id),
         :ok <- check_legal_entity_id(legal_entity_id, employee),
         :ok <- check_transition(employee, with_owner),
         active_employees <- get_active_employees(employee),
         :ok <- revoke_user_auth_data(employee, active_employees, headers),
         {:ok, _} <- OPS.terminate_declarations(id, get_consumer_id(headers), headers)
    do
      update_employee_status(employee, headers)
    end
  end

  def check_transition(%Employee{employee_type: @type_owner}, false) do
    {:error, {:conflict, "Owner can’t be deactivated"}}
  end
  def check_transition(%Employee{employee_type: @type_pharmacy_owner}, false) do
    {:error, {:conflict, "Pharmacy owner can’t be deactivated"}}
  end
  def check_transition(%Employee{is_active: true, status: @status_approved}, _), do: :ok
  def check_transition(_employee, _) do
    {:error, {:conflict, "Employee is DEACTIVATED and cannot be updated."}}
  end

  def get_active_employees(%{party_id: party_id, employee_type: employee_type}) do
    params = [
      status: @status_approved,
      is_active: true,
      party_id: party_id,
      employee_type: employee_type,
    ]

    Employee
    |> where([e], ^params)
    |> PRMRepo.all
  end

  def revoke_user_auth_data(%Employee{} = employee, headers) do
    client_id = employee.legal_entity_id
    role_name = employee.employee_type

    with parties <- PartyUsers.list!(%{party_id: employee.party_id}) do
      revoke_user_auth_data_async(parties, client_id, role_name, headers)
    end
  end
  def revoke_user_auth_data(_employee, _headers), do: :ok
  defp revoke_user_auth_data(%Employee{} = employee, active_employees, headers) when length(active_employees) <= 1 do
    revoke_user_auth_data(employee, headers)
  end
  defp revoke_user_auth_data(_, _, _), do: :ok

  def revoke_user_auth_data_async(user_parties, client_id, role_name, headers) do
    user_parties
    |> Enum.map(&(Task.async(fn ->
      {&1.user_id, delete_mithril_entities(&1.user_id, client_id, role_name, headers)}
    end)))
    |> Enum.map(&Task.await/1)
    |> check_async_error()
  end

  def delete_mithril_entities(user_id, client_id, role_name, headers) do
    with {:ok, _} <- Mithril.delete_user_roles_by_user_and_role_name(user_id, role_name, headers),
         {:ok, _} <- Mithril.delete_apps_by_user_and_client(user_id, client_id, headers),
         {:ok, _} <- Mithril.delete_tokens_by_user_and_client(user_id, client_id, headers)
    do
      :ok
    end
  end

  def check_async_error(resp) do
    resp
    |> Enum.reduce_while(nil, fn {id, resp}, acc ->
      case resp do
        {:error, err} ->
          Logger.error("Failed to revoke user roles with user_id \"#{id}\". Reason: #{inspect err}")
          {:halt, err}
        _ -> {:cont, acc}
      end
    end)
    |> case do
         nil -> :ok
         err -> {:error, err}
       end
  end

  def update_employee_status(%Employee{} = employee, headers) do
    params =
      headers
      |> get_update_employee_params()
      |> put_employee_status(employee)
    Employees.update(employee, params, get_consumer_id(headers))
  end

  defp get_update_employee_params(headers) do
    %{}
    |> Map.put(:updated_by, get_consumer_id(headers))
    |> Map.put(:end_date, Date.utc_today() |> Date.to_iso8601())
  end

  defp put_employee_status(params, %{employee_type: @type_owner}) do
    Map.put(params, :is_active, false)
  end
  defp put_employee_status(params, %{employee_type: @type_pharmacy_owner}) do
    Map.put(params, :is_active, false)
  end
  defp put_employee_status(params, _employee) do
    Map.put(params, :status, @status_dismissed)
  end

  defp check_legal_entity_id(client_id, %Employee{legal_entity_id: legal_entity_id}) do
    if client_id == legal_entity_id, do: :ok, else: {:error, :forbidden}
  end
end
