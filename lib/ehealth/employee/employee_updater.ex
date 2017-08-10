defmodule EHealth.Employee.EmployeeUpdater do
  @moduledoc false

  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias EHealth.API.PRM # deprecated
  alias EHealth.API.OPS
  alias EHealth.API.Mithril
  alias EHealth.PRM.Parties
  alias EHealth.PRM.Employees
  alias EHealth.PRM.Employees.Schema, as: Employee
  alias EHealth.Employee.API

  require Logger

  @employee_type_owner "OWNER"
  @employee_status_approved "APPROVED"
  @employee_status_dismissed "DISMISSED"

  def deactivate(id, headers) do
    with %Employee{} = employee  <- Employees.get_employee_by_id(id),
          :ok                    <- check_transition(employee),
         {:ok, active_employees} <- get_active_employees(employee, headers),
          :ok                    <- revoke_user_auth_data(employee, active_employees["data"], headers),
         {:ok, _}                <- OPS.terminate_declarations(id, get_consumer_id(headers), headers),
         {:ok, updated_employee} <- update_employee_status(employee, headers),
      do: {:ok, updated_employee}
  end

  def check_transition(%{is_active: true, status: @employee_status_approved}), do: :ok

  def check_transition(_employee) do
    {:error, {:conflict, "Employee is DEACTIVATED and cannot be updated."}}
  end

  def get_active_employees(%{party_id: party_id, employee_type: employee_type}, headers) do
    API.get_employees(%{
      status: @employee_status_approved,
      party_id: party_id,
      employee_type: employee_type,
    }, headers)
  end

  def revoke_user_auth_data(%Employee{} = employee, active_employees, headers) when length(active_employees) <= 1 do
    client_id = employee.legal_entity_id
    role_name = employee.employee_type

    employee.party_id
    |> Parties.get_party_users_by_party_id()
    |> revoke_user_auth_data_async(client_id, role_name, headers)
  end
  def revoke_user_auth_data(_employee, _active_employees, _headers), do: :ok

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
    headers
    |> get_update_employee_params()
    |> put_employee_status(employee)
    |> PRM.update_employee(employee.id, headers)
  end

  defp get_update_employee_params(headers) do
    %{}
    |> put_updated_by(headers)
    |> Map.put(:end_date, Date.utc_today() |> Date.to_iso8601())
  end

  def put_updated_by(data, headers) do
    Map.put(data, :updated_by, get_consumer_id(headers))
  end

  defp put_employee_status(params, %{employee_type: @employee_type_owner}) do
    Map.put(params, :is_active, false)
  end

  defp put_employee_status(params, _employee) do
    Map.put(params, :status, @employee_status_dismissed)
  end
end
