defmodule Jobs.LegalEntityMergeJob do
  @moduledoc false

  use Confex, otp_app: :core
  use TasKafka.Task, topic: "merge_legal_entities"

  import Core.API.Helpers.Connection, only: [get_consumer_id: 1, get_client_id: 1]
  import Ecto.Query

  alias Core.Employees.Employee
  alias Core.Employees.EmployeeUpdater
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.RelatedLegalEntity
  alias Core.LegalEntities.Validator, as: LegalEntitiesValidator
  alias Core.Log
  alias Core.Utils.TypesConverter
  alias Core.Validators.JsonSchema
  alias Core.Validators.Signature
  alias Ecto.Changeset
  alias Ecto.UUID
  alias TasKafka.Jobs, as: TasKafkaJobs

  defstruct [:job_id, :reason, :headers, :merged_from_legal_entity, :merged_to_legal_entity, :signed_content]

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]
  @media_storage_api Application.get_env(:core, :api_resolvers)[:media_storage]
  @status_active LegalEntity.status(:active)
  @type_msp LegalEntity.type(:msp)
  @merge_legal_entities_type Jobs.type(:merge_legal_entities)
  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def consume(%__MODULE__{} = job) do
    related_legal_entity_id = UUID.generate()

    with :ok <- store_signed_content(job.signed_content, related_legal_entity_id),
         :ok <- dismiss_employees(job),
         :ok <- update_client_type(job.merged_from_legal_entity.id, job.headers),
         :ok <- deactivate_client_tokens(job.merged_from_legal_entity.id, job.headers),
         {:ok, related} <- create_related_legal_entity(related_legal_entity_id, job) do
      TasKafkaJobs.processed(job.job_id, %{related_legal_entity_id: related.id})
    else
      {:error, %Changeset{} = changeset} ->
        errors =
          Changeset.traverse_errors(changeset, fn {msg, opts} ->
            Enum.reduce(opts, msg, fn {key, value}, acc ->
              String.replace(acc, "%{#{key}}", to_string(value))
            end)
          end)

        Log.error("Failed to merge legal entities with: #{inspect(errors)}")
        TasKafkaJobs.failed(job.job_id, errors)

      {:error, reason} ->
        Log.error("Failed to merge legal entities with: #{inspect(reason)}")
        TasKafkaJobs.failed(job.job_id, reason)
    end

    :ok
  rescue
    e ->
      Log.error("Failed to merge legal entities with: #{inspect(e)}")
      TasKafkaJobs.failed(job.job_id, "raised an exception: #{inspect(e)}")
      :ok
  end

  def consume(value) do
    Log.warn("Unknown kafka event: #{inspect(value)}")
    :ok
  end

  def create(%{signed_content: %{content: encoded_content, encoding: encoding}}, headers) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)

    with {:ok, %{"content" => content, "signers" => [signer]}} <-
           Signature.validate(encoded_content, encoding, headers),
         :ok <- Signature.check_drfo(signer, user_id, "merge_legal_entities"),
         :ok <- JsonSchema.validate(:legal_entity_merge_job, content),
         {:ok, legal_entity} <- LegalEntities.fetch_by_id(client_id),
         :ok <- LegalEntitiesValidator.validate_state_registry_number(legal_entity, signer),
         :ok <- validate_merged_id(content["merged_from_legal_entity"]["id"], content["merged_to_legal_entity"]["id"]),
         :ok <- validate_is_merged(:from, content),
         :ok <- validate_is_merged(:to, content),
         {:ok, legal_entity_from} <- validate_legal_entity("from", content),
         {:ok, legal_entity_to} <- validate_legal_entity("to", content),
         :ok <- validate_legal_entities_type(legal_entity_from, legal_entity_to) do
      meta = Map.take(content, ~w(merged_from_legal_entity merged_to_legal_entity))
      job_data = Map.merge(content, %{"headers" => headers, "signed_content" => encoded_content})

      __MODULE__
      |> struct(TypesConverter.strings_to_keys(job_data))
      |> produce(meta, type: @merge_legal_entities_type)
    end
  end

  defp validate_is_merged(:to, content),
    do:
      validate_related_legal_entity(
        content["merged_to_legal_entity"]["id"],
        "Merged to legal entity is in the process of reorganization itself"
      )

  defp validate_is_merged(:from, content),
    do:
      validate_related_legal_entity(
        content["merged_from_legal_entity"]["id"],
        "Merged from legal entity is already in the process of reorganization"
      )

  defp validate_related_legal_entity(id, message) do
    where = [merged_from_id: id, is_active: true]

    case LegalEntities.get_related_by(where) do
      %RelatedLegalEntity{} -> {:error, {:conflict, message}}
      _ -> :ok
    end
  end

  defp validate_legal_entity(direction, content) do
    %{"id" => id, "name" => name, "edrpou" => edrpou} = content["merged_#{direction}_legal_entity"]

    with {:ok, legal_entity} <- validate_is_active(direction, id),
         :ok <- validate_name(direction, legal_entity, name),
         :ok <- validate_edrpou(direction, legal_entity, edrpou),
         :ok <- validate_status(direction, legal_entity) do
      {:ok, legal_entity}
    end
  end

  defp validate_is_active(direction, id) do
    case LegalEntities.get_by_id(id) do
      %LegalEntity{is_active: true} = legal_entity -> {:ok, legal_entity}
      %LegalEntity{is_active: false} -> {:error, {:conflict, "Merged #{direction} legal entity must be active"}}
      _ -> {:error, {:conflict, "Merged #{direction} legal entity not found"}}
    end
  end

  defp validate_name(_direction, %{name: name}, request_name) when name == request_name, do: :ok
  defp validate_name(direction, _, _), do: {:error, {:"422", "Invalid merged #{direction} legal entity name"}}

  defp validate_edrpou(_direction, %{edrpou: edrpou}, request_edrpou) when edrpou == request_edrpou, do: :ok
  defp validate_edrpou(direction, _, _), do: {:error, {:"422", "Invalid merged #{direction} legal entity edrpou"}}

  defp validate_status(_direction, %{status: @status_active}), do: :ok
  defp validate_status(direction, _), do: {:error, {:conflict, "Merged #{direction} legal entity must be active"}}

  defp validate_merged_id(from_id, to_id) when from_id != to_id, do: :ok
  defp validate_merged_id(_, _), do: {:error, {:conflict, "Legator and successor of legal entities must be different"}}

  defp validate_legal_entities_type(%{type: @type_msp}, %{type: @type_msp}), do: :ok
  defp validate_legal_entities_type(_, _), do: {:error, {:conflict, "Invalid legal entity type"}}

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
    |> @read_prm_repo.all()
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
    |> @read_prm_repo.all()
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
          log_deactivate_employee_error(err, id)
          {:halt, {:error, "Cannot terminate employee `#{id}` with `#{inspect(err)}`"}}

        _ ->
          {:cont, acc}
      end
    end)
  end

  defp log_deactivate_employee_error(error, id) do
    Logger.error(fn ->
      Jason.encode!(%{
        "log_type" => "error",
        "message" => "Failed to deactivate employee with id \"#{id}\". Reason: #{inspect(error)}",
        "request_id" => Logger.metadata()[:request_id]
      })
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

  defp deactivate_client_tokens(client_id, headers) do
    case @mithril_api.deactivate_client_tokens(client_id, headers) do
      {:ok, _} ->
        :ok

      {:error, reason} ->
        {:error, "Cannot deactivate tokens for client `#{client_id}` with `#{inspect(reason)}`"}
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
      {:error, reason} -> {:error, "Failed to save signed content with `#{inspect(reason)}`"}
    end
  end
end
