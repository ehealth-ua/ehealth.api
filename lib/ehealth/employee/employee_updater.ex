defmodule EHealth.Employee.EmployeeUpdater do
  @moduledoc false

  import EHealth.Utils.Pipeline
  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias EHealth.API.PRM
  alias EHealth.API.Mithril
  alias EHealth.Employee.API

  require Logger

  @employee_type_owner "OWNER"
  @employee_status_approved "APPROVED"
  @employee_status_dismissed "DISMISSED"

  def deactivate(id, headers) do
    pipe_data = %{id: id, headers: headers}
    with {:ok, pipe_data} <- get_employee(pipe_data),
         {:ok, pipe_data} <- check_transition(pipe_data),
         {:ok, pipe_data} <- get_active_employees(pipe_data),
         {:ok, pipe_data} <- revoke_user_auth_data(pipe_data),
         {:ok, pipe_data} <- deactivate_declarations(pipe_data),
         {:ok, pipe_data} <- update_employee_status(pipe_data) do
         end_pipe({:ok, pipe_data})
    end
  end

  def get_employee(%{id: id, headers: headers} = pipe_data) do
    id
    |> API.get_employee_by_id(headers, false)
    |> case do
         {:ok, %{employee: employee}} -> put_in_pipe(employee, :employee, pipe_data)
         err -> err
       end
  end

  def check_transition(%{employee: %{"data" => %{"is_active" => true, "status" => @employee_status_approved}}} =
    pipe_data),
    do: {:ok, pipe_data}

  def check_transition(_pipe_data) do
    {:error, {:conflict, "Employee is DEACTIVATED and cannot be updated."}}
  end

  def get_active_employees(%{employee: %{"data" => employee}, headers: headers} = pipe_data) do
    %{
      status: @employee_status_approved,
      party_id: employee["party_id"],
      employee_type: employee["employee_type"],
    }
    |> API.get_employees(headers)
    |> put_success_api_response_in_pipe(:employees_active, pipe_data)
  end

  def revoke_user_auth_data(%{employees_active: %{"data" => employees}} = pipe_data) when length(employees) <= 1 do
    party_params = %{"party_id" => pipe_data.employee["party_id"]}

    with {:ok, %{"data" => party_users}} <- PRM.get_party_users(party_params, pipe_data.headers),
         :ok <- revoke_user_auth_data_async(party_users, pipe_data.headers)
    do
      {:ok, pipe_data}
    end
  end
  def revoke_user_auth_data(pipe_data), do: {:ok, pipe_data}

  def revoke_user_auth_data_async(user_parties, headers) do
    user_parties
    |> Enum.map(&(Task.async(fn ->
      {&1["user_id"], delete_mithril_entities(&1["user_id"], headers)}
    end)))
    |> Enum.map(&Task.await/1)
    |> check_async_error()
  end

  def delete_mithril_entities(user_id, headers) do
    with {:ok, _} <- Mithril.delete_user_roles_by_user(user_id, headers),
         {:ok, _} <- Mithril.delete_apps_by_user(user_id, headers),
         {:ok, _} <- Mithril.delete_tokens_by_user(user_id, headers)
    do
      :ok
    end
  end

  def check_async_error(resp) do
    resp
    |> Enum.reduce_while(nil, fn {id, resp}, acc ->
      case resp do
        {:error, err} ->
          Logger.error("Failed to revoke user roles with user_id \"#{id}\". Reason: #{inspect elem(err, 1)}")
          {:halt, err}
        _ -> {:cont, acc}
      end
    end)
    |> case do
         nil -> :ok
         err -> {:error, err}
       end
  end

  def deactivate_declarations(pipe_data) do
    {:ok, pipe_data}
  end

  def update_employee_status(%{id: id, headers: headers, employee: %{"data" => employee}} = pipe_data) do
    headers
    |> get_update_employee_params()
    |> put_employee_status(employee)
    |> PRM.update_employee(id, headers)
    |> put_success_api_response_in_pipe(:employee_updated, pipe_data)
  end

  def put_updated_by(data, headers) do
    data |> Map.put(:updated_by, get_consumer_id(headers))
  end

  defp get_update_employee_params(headers) do
    %{}
    |> put_updated_by(headers)
    |> Map.put(:end_date, Date.utc_today() |> Date.to_iso8601())
  end

  defp put_employee_status(params, %{"employee_type" => @employee_type_owner}) do
    Map.put(params, :is_active, false)
  end

  defp put_employee_status(params, _employee) do
    Map.put(params, :status, @employee_status_dismissed)
  end
end
