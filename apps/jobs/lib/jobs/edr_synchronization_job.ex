defmodule Jobs.EdrSynchronizationJob do
  @moduledoc false

  use Confex, otp_app: :core
  alias Core.LegalEntities.EdrData
  alias Core.LegalEntities.Validator
  alias Core.PRMRepo
  alias Core.V2.LegalEntities
  alias Jobs.Jabba.Client, as: JabbaClient
  alias Jobs.Jabba.Task, as: JabbaTask
  require Logger

  @edr_synchronization_task_type JabbaTask.type(:edr_synchronize)
  @edr_synchronization_job_type JabbaClient.type(:edr_synchronize)

  @rpc_edr_worker Application.get_env(:core, :rpc_edr_worker)

  def search_jobs(filter, order_by, limit, offset) do
    filter
    |> Kernel.++([{:type, :equal, @edr_synchronization_job_type}])
    |> JabbaClient.search_jobs(order_by, {offset, limit})
  end

  def get_job(id) do
    case JabbaClient.get_job(id) do
      {:ok, job} -> {:ok, job}
      nil -> {:ok, nil}
    end
  end

  def synchronize(legal_entity) do
    edr_response =
      case @rpc_edr_worker.run("edr_api", EdrApi.Rpc, :search_legal_entity, [%{code: legal_entity.edrpou}]) do
        {:ok, response} -> {:ok, response}
        {:error, _} -> {:error, {:conflict, "Legal Entity not found in EDR"}}
      end

    with {:ok, items} <- edr_response do
      active_items = Enum.filter(items, fn item -> item["state"] == 1 end)

      case active_items do
        [active_item] ->
          edr_response =
            case @rpc_edr_worker.run("edr_api", EdrApi.Rpc, :get_legal_entity_detailed_info, [active_item["id"]]) do
              {:ok, response} -> {:ok, response}
              {:error, _} -> {:error, {:conflict, "Legal Entity not found in EDR"}}
            end

          with {:ok, response} <- edr_response do
            data = %{
              "edrpou" => legal_entity.edrpou,
              "edr_id" => response["id"],
              "name" => response["names"]["name"],
              "short_name" => response["names"]["short"],
              "public_name" => response["names"]["display"],
              "legal_form" => response["olf_code"],
              "kveds" => response["activity_kinds"],
              "registration_address" => response["address"],
              "state" => response["state"],
              "updated_by" => Confex.fetch_env!(:core, :system_user)
            }

            changes =
              case Validator.validate_edr_data_fields(
                     response,
                     legal_entity.legal_form,
                     legal_entity.name,
                     legal_entity.addresses
                   ) do
                :ok -> %{}
                _ -> %{nhs_verified: false, nhs_reviewed: false}
              end

            create_edr_data(legal_entity, changes, data)
          end

        _ ->
          legal_entity
          |> LegalEntities.changeset(%{nhs_verified: false, nhs_reviewed: false, nhs_unverified_at: DateTime.utc_now()})
          |> PRMRepo.update()
      end
    end

    :ok
  rescue
    e ->
      Logger.error("Failed to synchronize legal entity #{legal_entity.id} with edr: #{inspect(e)}")
      {:error, e}
  end

  def create(legal_entity) do
    task = JabbaTask.new(@edr_synchronization_task_type, legal_entity)
    JabbaClient.create_job([task], @edr_synchronization_job_type, name: "Synchronize legal entity with edr")
  end

  defp create_edr_data(legal_entity, changes, data) do
    case PRMRepo.get_by(EdrData, %{edr_id: data["edr_id"]}) do
      %EdrData{} = edr_data ->
        legal_entity
        |> LegalEntities.changeset(Map.merge(changes, %{edr_data_id: edr_data.id}))
        |> PRMRepo.update()

      _ ->
        PRMRepo.transaction(fn ->
          edr_data =
            %EdrData{}
            |> EdrData.changeset(data)
            |> PRMRepo.insert()

          legal_entity
          |> LegalEntities.changeset(Map.merge(changes, %{edr_data_id: edr_data.id}))
          |> PRMRepo.update()
        end)
    end
  end
end
