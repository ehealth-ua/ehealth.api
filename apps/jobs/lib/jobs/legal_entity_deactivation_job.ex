defmodule Jobs.LegalEntityDeactivationJob do
  @moduledoc false

  use Confex, otp_app: :core
  import Core.API.Helpers.Connection, only: [get_consumer_id: 1]
  import Ecto.Query
  alias Core.ContractRequests
  alias Core.ContractRequests.CapitationContractRequest
  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.Contracts
  alias Core.Contracts.CapitationContract
  alias Core.Contracts.ReimbursementContract
  alias Core.Employees.Employee
  alias Core.Employees.EmployeeUpdater
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.PRMRepo
  alias Core.Repo
  alias Ecto.Changeset
  alias Jobs.Jabba.Client, as: JabbaClient
  alias Jobs.Jabba.Task, as: JabbaTask
  require Logger

  @status_active LegalEntity.status(:active)
  @status_closed LegalEntity.status(:closed)

  @status_reason "AUTO_DEACTIVATION_LEGAL_ENTITY"
  @legal_entity_deactivation_type JabbaClient.type(:legal_entity_deactivation)

  def search_jobs(filter, order_by, limit, offset) do
    filter
    |> Keyword.put(:type, @legal_entity_deactivation_type)
    |> JabbaClient.search_jobs(order_by, {limit, offset})
  end

  def get_job(id) do
    case JabbaClient.get_job(id) do
      {:ok, job} -> {:ok, prepare_meta(job)}
      nil -> {:ok, nil}
    end
  end

  defp prepare_meta(%{meta: meta} = job) do
    Map.merge(job, Map.take(meta, ~w(deactivated_legal_entity)a))
  end

  defp prepare_meta(job), do: job

  def deactivate(entity, actor_id) do
    with :ok <- process_entity(entity, actor_id) do
      :ok
    else
      {:error, %Changeset{} = changeset} ->
        errors =
          Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)

        Logger.error("Failed to deactivate legal entity with: #{inspect(errors)}")
        {:error, errors}

      {:error, reason} ->
        Logger.error("Failed to deactivate legal entity with: #{inspect(reason)}")
        {:error, reason}
    end
  rescue
    e ->
      Logger.error("Failed to deactivate legal entity with: #{inspect(e)}")
      {:error, inspect(e)}
  end

  defp process_entity(%{entity: entity, schema: "legal_entity"}, actor_id) do
    with {:ok, _} <- update_legal_entity_status(entity, actor_id), do: :ok
  end

  defp process_entity(%{entity: entity, schema: "employee"}, actor_id) do
    with {:ok, _} <- EmployeeUpdater.deactivate(entity, @status_reason, [], actor_id, true), do: :ok
  end

  defp process_entity(%{entity: entity, schema: "contract"}, actor_id) do
    with {:ok, _} <- Contracts.do_terminate(actor_id, entity, %{"status_reason" => @status_reason}),
         do: :ok
  end

  defp process_entity(%{entity: entity, schema: "contract_request"}, actor_id) do
    with {:ok, _} <-
           ContractRequests.do_terminate(actor_id, entity, %{"status_reason" => "auto_deactivation_legal_entity"}),
         do: :ok
  end

  defp process_entity(_, _), do: {:error, "Invalid entity"}

  def create(id, headers) do
    user_id = get_consumer_id(headers)

    with {:ok, legal_entity} <- LegalEntities.fetch_by_id(id),
         :ok <- check_transition(legal_entity),
         :ok <- LegalEntities.check_nhs_reviewed(legal_entity, true) do
      tasks = get_legal_entity_deactivation_tasks(legal_entity, user_id)

      opts = [
        name: "Deactivate legal entity",
        meta: %{deactivated_legal_entity: Map.take(legal_entity, ~w(id name edrpou)a)}
      ]

      JabbaClient.create_job(tasks, @legal_entity_deactivation_type, opts)
    end
  end

  defp get_legal_entity_deactivation_tasks(legal_entity, actor_id) do
    Enum.map(get_entities_to_deactivate(legal_entity), &prepare_task(&1, actor_id))
  end

  defp get_entities_to_deactivate(legal_entity) do
    %{
      schema: "legal_entity",
      entity: legal_entity
    }
    |> List.wrap()
    |> Enum.concat([
      get_employees_to_deactivate(legal_entity.id),
      get_contract_requests_to_deactivate(legal_entity.id),
      get_contracts_to_deactivate(legal_entity.id)
    ])
    |> List.flatten()
  end

  defp check_transition(%LegalEntity{is_active: true, status: @status_active}), do: :ok

  defp check_transition(_legal_entity) do
    {:error, {:conflict, "Legal entity is not ACTIVE and cannot be updated"}}
  end

  defp get_employees_to_deactivate(legal_entity_id) do
    Employee
    |> select([e], %{schema: "employee", entity: e})
    |> where([e], e.legal_entity_id == ^legal_entity_id)
    |> where([e], e.is_active)
    |> where([e], e.status == ^Employee.status(:approved))
    |> PRMRepo.all()
  end

  defp get_contract_requests_to_deactivate(legal_entity_id) do
    Enum.concat([
      get_capitation_contract_requests_to_deactivate(legal_entity_id),
      get_reimbursement_contract_requests_to_deactivate(legal_entity_id)
    ])
  end

  defp get_capitation_contract_requests_to_deactivate(legal_entity_id) do
    CapitationContractRequest
    |> select([cr], %{schema: "contract_request", entity: cr})
    |> where([cr], cr.type == ^CapitationContractRequest.type())
    |> where([cr], cr.contractor_legal_entity_id == ^legal_entity_id)
    |> where(
      [cr],
      cr.status in ^[
        CapitationContractRequest.status(:new),
        CapitationContractRequest.status(:in_process),
        CapitationContractRequest.status(:approved),
        CapitationContractRequest.status(:pending_nhs_sign),
        CapitationContractRequest.status(:nhs_signed)
      ]
    )
    |> Repo.all()
  end

  defp get_reimbursement_contract_requests_to_deactivate(legal_entity_id) do
    ReimbursementContractRequest
    |> select([cr], %{schema: "contract_request", entity: cr})
    |> where([cr], cr.type == ^ReimbursementContractRequest.type())
    |> where([cr], cr.contractor_legal_entity_id == ^legal_entity_id)
    |> where(
      [cr],
      cr.status in ^[
        ReimbursementContractRequest.status(:new),
        ReimbursementContractRequest.status(:in_process),
        ReimbursementContractRequest.status(:approved),
        ReimbursementContractRequest.status(:pending_nhs_sign),
        ReimbursementContractRequest.status(:nhs_signed)
      ]
    )
    |> Repo.all()
  end

  defp get_contracts_to_deactivate(legal_entity_id) do
    Enum.concat([
      get_capitation_contracts_to_deactivate(legal_entity_id),
      get_reimbursement_contracts_to_deactivate(legal_entity_id)
    ])
  end

  defp get_capitation_contracts_to_deactivate(legal_entity_id) do
    CapitationContract
    |> select([c], %{schema: "contract", entity: c})
    |> where([c], c.type == ^CapitationContract.type())
    |> where([c], c.contractor_legal_entity_id == ^legal_entity_id)
    |> where([c], c.status == ^CapitationContract.status(:verified))
    |> where([c], c.is_active)
    |> PRMRepo.all()
  end

  defp get_reimbursement_contracts_to_deactivate(legal_entity_id) do
    ReimbursementContract
    |> select([c], %{schema: "contract", entity: c})
    |> where([c], c.type == ^ReimbursementContract.type())
    |> where([c], c.contractor_legal_entity_id == ^legal_entity_id)
    |> where([c], c.status == ^ReimbursementContract.status(:verified))
    |> where([c], c.is_active)
    |> PRMRepo.all()
  end

  defp update_legal_entity_status(legal_entity, actor_id) do
    params =
      actor_id
      |> get_update_legal_entity_params()
      |> put_legal_entity_status(@status_closed)

    legal_entity
    |> LegalEntities.changeset(params)
    |> PRMRepo.update_and_log(actor_id)
  end

  defp get_update_legal_entity_params(actor_id) do
    %{
      updated_by: actor_id,
      end_date: Date.utc_today() |> Date.to_iso8601()
    }
  end

  defp prepare_task(%{schema: schema} = entity, actor_id) do
    type = JabbaTask.type(:"deactivate_#{schema}")
    JabbaTask.new(type, entity, actor_id)
  end

  def put_legal_entity_status(params, status), do: Map.put(params, :status, status)
end
