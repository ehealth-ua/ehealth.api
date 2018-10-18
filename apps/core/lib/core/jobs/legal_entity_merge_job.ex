defmodule Core.Jobs.LegalEntityMergeJob do
  @moduledoc false

  use Confex, otp_app: :core
  use TasKafka.Task, topic: "merge_legal_entities"
  import Core.API.Helpers.Connection, only: [get_consumer_id: 1]
  import Ecto.Query
  alias Core.Employees.Employee
  alias Core.Employees.EmployeeUpdater
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntityUpdater
  alias Core.LegalEntities.RelatedLegalEntity
  alias Core.PRMRepo
  alias Ecto.Changeset
  alias Ecto.UUID
  alias TasKafka.Jobs
  require Logger

  defstruct [:job_id, :reason, :headers, :merged_from_legal_entity, :merged_to_legal_entity, :signed_content]

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]
  @media_storage_api Application.get_env(:core, :api_resolvers)[:media_storage]

  def consume(%__MODULE__{} = job) do
    related_legal_entity_id = UUID.generate()

    with :ok <- store_signed_content(job.signed_content, related_legal_entity_id),
         :ok <- dismiss_employees(job),
         :ok <- update_client_type(job.merged_from_legal_entity.id, job.headers),
         {:ok, related} <- create_related_legal_entity(related_legal_entity_id, job) do
      Jobs.processed(job.job_id, %{related_legal_entity_id: related.id})
    else
      {:error, %Changeset{} = changeset} ->
        errors =
          Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)

        Logger.error("failed to merge legal entities with: #{inspect(errors)}")
        Jobs.failed(job.job_id, errors)

      {:error, reason} ->
        Logger.error("failed to merge legal entities with: #{inspect(reason)}")
        Jobs.failed(job.job_id, reason)
    end

    :ok
  rescue
    e ->
      Logger.error("failed to merge legal entities with: #{inspect(e)}")
      Jobs.failed(job.job_id, "raised an exception: #{inspect(e)}")
      :ok
  end

  def consume(value) do
    Logger.warn(fn -> "unknown kafka event: #{inspect(value)}" end)
    :ok
  end

  defp dismiss_employees(%{merged_from_legal_entity: merged_from, merged_to_legal_entity: merged_to} = job) do
    merged_from_employees = get_merged_from_employees(merged_from.id)
    merged_to_employees = get_merged_to_employees(merged_from_employees, merged_to.id)

    merged_from_employees
    |> Enum.filter(fn %{party_id: party_id, speciality: %{"speciality" => speciality}} ->
      {party_id, speciality} not in merged_to_employees
    end)
    |> terminate_employees_declarations(job.headers)
  end

  defp get_merged_from_employees(merged_from_legal_entity_id) do
    where = [
      legal_entity_id: merged_from_legal_entity_id,
      employee_type: Employee.type(:doctor),
      status: Employee.status(:approved)
    ]

    Employee
    |> where(^where)
    |> PRMRepo.all()
  end

  defp get_merged_to_employees([], _to_id), do: []

  defp get_merged_to_employees(from_employees, merged_to_legal_entity_id) do
    {party_ids, specialities} =
      Enum.reduce(from_employees, {[], []}, fn employee, {parties, specialities} ->
        {parties ++ [employee.party_id], specialities ++ [employee.speciality["speciality"]]}
      end)

    Employee
    |> select([e], {e.party_id, fragment("?->>?", e.speciality, "speciality")})
    |> where([e], e.legal_entity_id == ^merged_to_legal_entity_id)
    |> where([e], e.employee_type == ^Employee.type(:doctor))
    |> where([e], e.status == ^Employee.status(:approved))
    |> where([e], e.party_id in ^party_ids)
    |> where([e], fragment("?->>'speciality'", e.speciality) in ^Enum.uniq(specialities))
    |> PRMRepo.all()
  end

  defp terminate_employees_declarations([], _), do: :ok

  defp terminate_employees_declarations(employees, headers) do
    employees
    |> Enum.map(
      &Task.async(fn ->
        employee_id = Map.get(&1, :id)
        legal_entity_id = Map.get(&1, :legal_entity_id)
        {employee_id, EmployeeUpdater.deactivate(employee_id, legal_entity_id, "auto_reorganization", headers, false)}
      end)
    )
    |> Enum.map(&Task.await/1)
    |> Enum.reduce_while(:ok, fn {id, resp}, acc ->
      case resp do
        {:error, err} ->
          LegalEntityUpdater.log_deactivate_employee_error(err, id)
          {:halt, {:error, "Cannot terminate employee `#{id}` with `#{inspect(err)}`"}}

        _ ->
          {:cont, acc}
      end
    end)
  end

  defp update_client_type(legal_entity_id, headers) do
    params = %{"id" => legal_entity_id, "client_type_id" => config()[:client_type_id]}

    case @mithril_api.put_client(params, headers) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        {:error, "Cannot update client type on Mithril for client `#{legal_entity_id}` with `#{inspect(reason)}`"}
    end
  end

  defp create_related_legal_entity(id, job) do
    inserted_by = get_consumer_id(job.headers)

    LegalEntities.create(
      %RelatedLegalEntity{},
      %{
        id: id,
        reason: job.reason,
        merged_from_id: job.merged_from_legal_entity.id,
        merged_to_id: job.merged_to_legal_entity.id,
        inserted_by: inserted_by,
        is_active: true
      },
      inserted_by
    )
  end

  defp store_signed_content(signed_content, id) do
    resource_name = config()[:media_storage_resource_name]

    case @media_storage_api.store_signed_content(signed_content, :related_legal_entity_bucket, id, resource_name, []) do
      {:ok, _} -> :ok
      _error -> {:error, "Failed to save signed content"}
    end
  end
end
