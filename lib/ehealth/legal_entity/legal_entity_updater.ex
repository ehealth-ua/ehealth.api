defmodule EHealth.LegalEntity.LegalEntityUpdater do
  @moduledoc false

  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias EHealth.PRM.LegalEntities
  alias EHealth.Employee.EmployeeUpdater
  alias EHealth.API.PRM
  alias EHealth.PRM.LegalEntities.Schema, as: LegalEntity
  alias EHealth.PRM.Employees

  require Logger

  @legal_entity_status_active "ACTIVE"

  def deactivate(id, headers) do
    with legal_entity <- LegalEntities.get_legal_entity_by_id!(id),
         :ok <- check_transition(legal_entity),
         :ok <- deactivate_employees(legal_entity, headers),
         {:ok, legal_entity} <- update_legal_entity_status(legal_entity, headers)
    do
     {:ok, legal_entity}
    end
  end

  def check_transition(%LegalEntity{is_active: true, status: @legal_entity_status_active}), do: :ok
  def check_transition(_legal_entity) do
    {:error, {:conflict, "Legal entity is not ACTIVE and cannot be updated"}}
  end

  def deactivate_employees(%LegalEntity{} = legal_entity, headers, starting_after \\ nil) do
    employees_resp = %{
      status: "APPROVED",
      is_active: true,
      legal_entity_id: legal_entity.id,
    }
    |> set_paging_after(starting_after)
    |> Employees.get_employees

    case employees_resp do
      {employees, %Ecto.Paging{cursors: cursors, has_more: true}} ->
        error =
          employees
          |> deactivate_employees_page(headers)
          |> check_deactivated_employees_error()
        case error do
          nil -> deactivate_employees(legal_entity, headers, cursors["starting_after"])
          error -> {:error, error}
        end
      {employees, %Ecto.Paging{has_more: false}} ->
        error =
          employees
          |> deactivate_employees_page(headers)
          |> check_deactivated_employees_error()
        case error do
          nil -> :ok
          error -> {:error, error}
        end
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Find first error
  """
  def check_deactivated_employees_error(deactivated_employees) do
    deactivated_employees
    |> Enum.reduce_while(nil, fn {id, resp}, acc ->
      case resp do
        {:error, err} ->
          log_deactivate_employee_error(err, id)
          {:halt, err}
        _ -> {:cont, acc}
      end
    end)
  end

  def deactivate_employees_page(employees, headers) do
    employees
    |> Enum.map(&(Task.async(fn ->
      {Map.get(&1, :id), EmployeeUpdater.deactivate(Map.get(&1, :id), headers)}
    end)))
    |> Enum.map(&Task.await/1)
  end

  def update_legal_entity_status(%LegalEntity{} = legal_entity, headers) do
    headers
    |> get_update_legal_entity_params()
    |> put_legal_entity_status()
    |> PRM.update_legal_entity(legal_entity.id, headers)
  end

  defp get_update_legal_entity_params(headers) do
    %{
      updated_by: get_consumer_id(headers),
      end_date: Date.utc_today() |> Date.to_iso8601()
    }
  end

  def put_legal_entity_status(params), do: Map.put(params, "status", "CLOSED")

  defp set_paging_after(params, nil), do: params
  defp set_paging_after(params, starting_after) do
    Map.put(params, "starting_after", starting_after)
  end

  defp log_deactivate_employee_error(error, id) do
    Logger.error("Failed to deactivate employee with id \"#{id}\". Reason: #{inspect error}")
  end
end
