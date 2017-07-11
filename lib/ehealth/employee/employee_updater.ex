defmodule EHealth.Employee.EmployeeUpdater do
  @moduledoc false

  use OkJose

  import EHealth.Utils.Pipeline
  import EHealth.Utils.Connection, only: [get_consumer_id: 1, get_client_id: 1]

  alias EHealth.API.PRM
  alias EHealth.API.Mithril
  alias EHealth.Employee.API

  @employee_type_owner "OWNER"
  @employee_status_approved "APPROVED"
  @employee_status_dismissed "DISMISSED"

  def deactivate(id, headers) do
    {:ok, %{id: id, headers: headers}}
    |> get_employee()
    |> check_transition()
    |> get_active_employees()
    |> revoke_user_roles()
    |> deactivate_declarations()
    |> update_employee_status()
    |> ok()
    |> end_pipe()
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
      party_id: employee["party_id"],
      employee_type: employee["employee_type"],
    }
    |> API.get_employees(headers)
    |> put_success_api_response_in_pipe(:employees_active, pipe_data)
  end

  def revoke_user_roles(%{employees_active: %{"data" => employees}} = pipe_data) when length(employees) == 1 do
    with :ok <- delete_user_roles(pipe_data.headers),
         :ok <- delete_mithril_entities(:get_tokens, :delete_token, pipe_data.headers),
         :ok <- delete_mithril_entities(:get_apps, :delete_app, pipe_data.headers)
    do
      {:ok, pipe_data}
    end
  end
  def revoke_user_roles(pipe_data), do: {:ok, pipe_data}

  def delete_user_roles(headers) do
    user_id = get_consumer_id(headers)
    params = [client_id: get_client_id(headers)]

    case Mithril.get_user_roles(user_id, params, headers) do

      {:ok, %{"data" => list}} -> Enum.each(list, fn(%{"role_id" => id}) ->
          Mithril.delete_user_role(user_id, id, headers)
        end)

      err -> err
    end
  end

  def delete_mithril_entities(call_list, call_delete, headers) do
    params = [client_id: get_client_id(headers)]

    case apply(Mithril, call_list, [params, headers]) do
      {:ok, %{"data" => list}} -> Enum.each(list, fn(%{"id" => id}) ->
          apply(Mithril, call_delete, [id, headers])
        end)

      err -> err
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
