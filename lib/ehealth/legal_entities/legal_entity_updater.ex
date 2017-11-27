defmodule EHealth.LegalEntities.LegalEntityUpdater do
  @moduledoc false

  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias EHealth.LegalEntities
  alias EHealth.Employees.EmployeeUpdater
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.Employees.Employee
  alias EHealth.Employees

  require Logger

  @status_active LegalEntity.status(:active)
  @status_closed LegalEntity.status(:closed)

  @employee_status_approved Employee.status(:approved)

  def deactivate(id, headers) do
    with legal_entity <- LegalEntities.get_by_id!(id),
         :ok <- check_transition(legal_entity),
         :ok <- deactivate_employees(legal_entity, headers)
    do
      update_legal_entity_status(legal_entity, headers)
    end
  end

  def check_transition(%LegalEntity{is_active: true, status: @status_active}), do: :ok
  def check_transition(_legal_entity) do
    {:error, {:conflict, "Legal entity is not ACTIVE and cannot be updated"}}
  end

  def deactivate_employees(%LegalEntity{} = legal_entity, headers) do
    %{
      status: @employee_status_approved,
      is_active: true,
      legal_entity_id: legal_entity.id,
    }
    |> Employees.list
    |> Enum.map(&(Task.async(fn ->
      id = Map.get(&1, :id)
      {id, EmployeeUpdater.deactivate(%{"id" => id, "legal_entity_id" => legal_entity.id}, headers, true)}
    end)))
    |> Enum.map(&Task.await/1)
    |> Enum.reduce_while(:ok, fn {id, resp}, acc ->
      case resp do
        {:error, err} ->
          log_deactivate_employee_error(err, id)
          {:halt, err}
        _ -> {:cont, acc}
      end
    end)
  end

  def update_legal_entity_status(%LegalEntity{} = legal_entity, headers) do
    with params <- get_update_legal_entity_params(headers),
         params <- put_legal_entity_status(params)
    do
      LegalEntities.update(legal_entity, params, get_consumer_id(headers))
    end
  end

  defp get_update_legal_entity_params(headers) do
    %{
      updated_by: get_consumer_id(headers),
      end_date: Date.utc_today() |> Date.to_iso8601()
    }
  end

  def put_legal_entity_status(params), do: Map.put(params, :status, @status_closed)

  defp log_deactivate_employee_error(error, id) do
    Logger.error("Failed to deactivate employee with id \"#{id}\". Reason: #{inspect error}")
  end
end
