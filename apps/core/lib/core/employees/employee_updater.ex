defmodule Core.Employees.EmployeeUpdater do
  @moduledoc false

  import Ecto.Query
  import Core.API.Helpers.Connection, only: [get_consumer_id: 1]

  alias Core.Employees
  alias Core.Employees.Employee
  alias Core.PartyUsers

  require Logger

  @type_owner Employee.type(:owner)
  @type_admin Employee.type(:admin)
  @type_pharmacy_owner Employee.type(:pharmacy_owner)

  @status_approved Employee.status(:approved)
  @status_dismissed Employee.status(:dismissed)

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  @producer Application.get_env(:core, :kafka)[:producer]

  @rpc_worker Application.get_env(:core, :rpc_worker)

  def deactivate(%{"id" => id} = params, headers, with_owner \\ false) do
    deactivate(id, params["legal_entity_id"], "auto_employee_deactivate", headers, with_owner)
  end

  def deactivate(employee_id, legal_entity_id, reason, headers, with_owner \\ false) do
    user_id = get_consumer_id(headers)

    with {:ok, employee} <- Employees.fetch_by_id(employee_id),
         :ok <- check_legal_entity_id(legal_entity_id, employee),
         :ok <- check_transition(employee, with_owner) do
      do_deactivate(employee, reason, headers, user_id, false)
    end
  end

  def do_deactivate(employee, reason, headers, user_id, skip_contracts_suspend?) do
    deactivation_event = %{"employee_id" => employee.id, "actor_id" => user_id, "reason" => reason}

    with active_employees <- get_active_employees(employee),
         :ok <- revoke_user_auth_data(employee, active_employees, headers),
         :ok <- @producer.publish_deactivate_declaration_event(deactivation_event) do
      set_employee_status_as_dismissed(employee, reason, user_id, skip_contracts_suspend?)
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
      employee_type: employee_type
    ]

    Employee
    |> where([e], ^params)
    |> @read_prm_repo.all()
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
    |> Enum.map(
      &Task.async(fn ->
        {&1.user_id, delete_mithril_entities(&1.user_id, client_id, role_name, headers)}
      end)
    )
    |> Enum.map(&Task.await/1)
    |> check_async_error()
  end

  def delete_mithril_entities(user_id, client_id, role_name, headers) do
    with :ok <- @rpc_worker.run("mithril_api", Core.Rpc, :delete_user_role, [user_id, client_id, role_name]),
         {:ok, _} <- @mithril_api.delete_apps_by_user_and_client(user_id, client_id, headers),
         {:ok, _} <- @mithril_api.delete_tokens_by_user_and_client(user_id, client_id, headers) do
      :ok
    end
  end

  def check_async_error(resp) do
    resp
    |> Enum.reduce_while(nil, fn {id, resp}, acc ->
      case resp do
        {:error, err} ->
          log_error(id, err)
          {:halt, err}

        _ ->
          {:cont, acc}
      end
    end)
    |> case do
      nil -> :ok
      err -> {:error, err}
    end
  end

  def set_employee_status_as_dismissed(%Employee{} = employee, reason, user_id, skip_contracts_suspend?) do
    params =
      user_id
      |> get_deactivate_employee_params()
      |> put_employee_status(employee, reason)

    if employee.employee_type in [@type_owner, @type_admin] and !skip_contracts_suspend? do
      Employees.update_with_ops_contract(employee, params, user_id)
    else
      Employees.update(employee, params, user_id)
    end
  end

  defp get_deactivate_employee_params(user_id) do
    %{updated_by: user_id, end_date: Date.utc_today() |> Date.to_iso8601()}
  end

  defp put_employee_status(params, %{employee_type: @type_owner}, reason) do
    Map.merge(params, %{is_active: false, status_reason: reason})
  end

  defp put_employee_status(params, %{employee_type: @type_pharmacy_owner}, reason) do
    Map.merge(params, %{is_active: false, status_reason: reason})
  end

  defp put_employee_status(params, _employee, reason) do
    Map.merge(params, %{status: @status_dismissed, status_reason: reason})
  end

  defp check_legal_entity_id(client_id, %Employee{legal_entity_id: legal_entity_id}) do
    if client_id == legal_entity_id, do: :ok, else: {:error, :forbidden}
  end

  defp log_error(id, message) do
    Logger.error("Failed to revoke user roles with user_id \"#{id}\". Reason: #{inspect(message)}")
  end
end
