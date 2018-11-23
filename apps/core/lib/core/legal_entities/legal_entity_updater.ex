defmodule Core.LegalEntities.LegalEntityUpdater do
  @moduledoc false

  import Core.API.Helpers.Connection, only: [get_consumer_id: 1]

  alias Core.Employees
  alias Core.Employees.Employee
  alias Core.Employees.EmployeeUpdater
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity

  require Logger

  @status_active LegalEntity.status(:active)
  @status_closed LegalEntity.status(:closed)

  @employee_status_approved Employee.status(:approved)

  def deactivate(id, headers, check_nhs_reviewed? \\ false) do
    with {:ok, legal_entity} <- LegalEntities.fetch_by_id(id),
         :ok <- check_transition(legal_entity),
         :ok <- LegalEntities.check_nhs_reviewed(legal_entity, check_nhs_reviewed?),
         :ok <- deactivate_employees(legal_entity, headers) do
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
      legal_entity_id: legal_entity.id
    }
    |> Employees.list()
    |> Enum.map(
      &Task.async(fn ->
        id = Map.get(&1, :id)
        {id, EmployeeUpdater.deactivate(%{"id" => id, "legal_entity_id" => legal_entity.id}, headers, true)}
      end)
    )
    |> Enum.map(&Task.await/1)
    |> Enum.reduce_while(:ok, fn {id, resp}, acc ->
      case resp do
        {:error, err} ->
          log_deactivate_employee_error(err, id)
          {:halt, {:error, err}}

        _ ->
          {:cont, acc}
      end
    end)
  end

  def update_legal_entity_status(%LegalEntity{} = legal_entity, headers) do
    params =
      headers
      |> get_update_legal_entity_params()
      |> put_legal_entity_status()

    legal_entity
    |> LegalEntities.changeset(params)
    |> LegalEntities.update_with_ops_contract(headers)
  end

  defp get_update_legal_entity_params(headers) do
    %{
      updated_by: get_consumer_id(headers),
      end_date: Date.utc_today() |> Date.to_iso8601()
    }
  end

  def put_legal_entity_status(params), do: Map.put(params, :status, @status_closed)

  def log_deactivate_employee_error(error, id) do
    Logger.error(fn ->
      Jason.encode!(%{
        "log_type" => "error",
        "message" => "Failed to deactivate employee with id \"#{id}\". Reason: #{inspect(error)}",
        "request_id" => Logger.metadata()[:request_id]
      })
    end)
  end
end
