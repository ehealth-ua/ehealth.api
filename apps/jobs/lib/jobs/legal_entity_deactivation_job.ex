defmodule Jobs.LegalEntityDeactivationJob do
  @moduledoc false

  use Confex, otp_app: :core
  use TasKafka.Task, topic: "deactivate_legal_entity_event"
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
  alias TasKafka.Jobs, as: TasKafkaJobs
  require Logger

  defstruct [:job_id, :actor_id, :records]

  @status_active LegalEntity.status(:active)
  @status_closed LegalEntity.status(:closed)
  @legal_entity_deactivation_type Jobs.type(:legal_entity_deactivation)

  def consume(%__MODULE__{job_id: job_id, actor_id: actor_id, records: [record | records]}) do
    with :ok <- process_record(record, actor_id),
         :ok <- produce_without_job(%__MODULE__{job_id: job_id, actor_id: actor_id, records: records}) do
      :ok
    else
      {:error, %Changeset{} = changeset} ->
        errors =
          Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)

        Logger.error("failed to deactivate legal entity with: #{inspect(errors)}")
        TasKafkaJobs.failed(job_id, errors)
        {:error, changeset}

      {:error, reason} ->
        Logger.error("failed to deactivate legal entity with: #{inspect(reason)}")
        TasKafkaJobs.failed(job_id, reason)
        {:error, reason}
    end
  rescue
    e ->
      Logger.error("failed to deactivate legal entity with: #{inspect(e)}")
      TasKafkaJobs.failed(job_id, "raised an exception: #{inspect(e)}")
  end

  def consume(%__MODULE__{job_id: job_id, actor_id: _, records: []}) do
    TasKafkaJobs.processed(job_id, :done)
    :ok
  end

  def consume(value) do
    Logger.warn(fn -> "unknown kafka event: #{inspect(value)}" end)
    :ok
  end

  defp process_record(%{record: record, schema: "legal_entity"}, actor_id) do
    with {:ok, _} <- update_legal_entity_status(record, actor_id), do: :ok
  end

  defp process_record(%{record: record, schema: "employee"}, actor_id) do
    with {:ok, _} <- EmployeeUpdater.do_deactivate(record, "auto_deactivation_legal_entity", [], actor_id, true),
         do: :ok
  end

  defp process_record(%{record: record, schema: "contract"}, actor_id) do
    with {:ok, _} <- Contracts.do_terminate(actor_id, record, %{"status_reason" => "auto_deactivation_legal_entity"}),
         do: :ok
  end

  defp process_record(%{record: record, schema: "contract_request"}, actor_id) do
    with {:ok, _} <-
           ContractRequests.do_terminate(actor_id, record, %{"status_reason" => "auto_deactivation_legal_entity"}),
         do: :ok
  end

  defp process_record(_, _), do: {:error, "Invalid record"}

  def create(id, headers) do
    user_id = get_consumer_id(headers)

    with {:ok, legal_entity} <- LegalEntities.fetch_by_id(id),
         :ok <- check_transition(legal_entity),
         :ok <- LegalEntities.check_nhs_reviewed(legal_entity, true) do
      job_data = get_legal_entity_deactivation_event_data(legal_entity, user_id)
      meta = %{deactivated_legal_entity: Map.take(legal_entity, ~w(id name edrpou)a)}

      __MODULE__
      |> struct(job_data)
      |> produce(meta, type: @legal_entity_deactivation_type)
    end
  end

  defp get_legal_entity_deactivation_event_data(legal_entity, user_id) do
    %{
      actor_id: user_id,
      records: get_records_to_deactivate(legal_entity)
    }
  end

  defp get_records_to_deactivate(legal_entity) do
    %{
      schema: "legal_entity",
      record: legal_entity
    }
    |> List.wrap()
    |> Enum.concat([
      get_employees_to_deactivate(legal_entity.id),
      get_contract_requests_to_deactivate(legal_entity.id),
      get_contracts_to_deactivate(legal_entity.id)
    ])
    |> List.flatten()
  end

  def check_transition(%LegalEntity{is_active: true, status: @status_active}), do: :ok

  def check_transition(_legal_entity) do
    {:error, {:conflict, "Legal entity is not ACTIVE and cannot be updated"}}
  end

  defp get_employees_to_deactivate(legal_entity_id) do
    Employee
    |> select([e], %{schema: "employee", record: e})
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
    |> select([cr], %{schema: "contract_request", record: cr})
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
    |> select([cr], %{schema: "contract_request", record: cr})
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
    |> select([c], %{schema: "contract", record: c})
    |> where([c], c.type == ^CapitationContract.type())
    |> where([c], c.contractor_legal_entity_id == ^legal_entity_id)
    |> where([c], c.status == ^CapitationContract.status(:verified))
    |> where([c], c.is_active)
    |> PRMRepo.all()
  end

  defp get_reimbursement_contracts_to_deactivate(legal_entity_id) do
    ReimbursementContract
    |> select([c], %{schema: "contract", record: c})
    |> where([c], c.type == ^ReimbursementContract.type())
    |> where([c], c.contractor_legal_entity_id == ^legal_entity_id)
    |> where([c], c.status == ^ReimbursementContract.status(:verified))
    |> where([c], c.is_active)
    |> PRMRepo.all()
  end

  def update_legal_entity_status(legal_entity, actor_id) do
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

  def put_legal_entity_status(params, status), do: Map.put(params, :status, status)
end
