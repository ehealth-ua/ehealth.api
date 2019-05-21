defmodule EdrValidationsConsumer.Kafka.Consumer do
  @moduledoc false

  alias Core.LegalEntities.EdrData
  alias Core.LegalEntities.LegalEntity
  alias Core.PRMRepo
  import Ecto.Changeset
  import Ecto.Query
  require Logger

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]
  @rpc_edr_worker Application.get_env(:core, :rpc_edr_worker)

  def handle_message(%{offset: offset, value: message}) do
    value = :erlang.binary_to_term(message)
    Logger.debug(fn -> "message: " <> inspect(value) end)
    Logger.info(fn -> "offset: #{offset}" end)
    :ok = consume(value)
  end

  def consume(%{"id" => id}) do
    case get_edr_data(id) do
      {:ok, edr_data} ->
        do_consume(edr_data)
        :ok

      _ ->
        :ok
    end
  end

  def consume(value) do
    Logger.warn("Invalid message #{inspect(value)}")
    :ok
  end

  defp do_consume(%EdrData{state: previous_state} = edr_data) do
    id = edr_data.id

    with {:ok, response} <- get_legal_entity_from_edr(edr_data.edr_id) do
      data = %{
        "name" => response["names"]["name"],
        "short_name" => response["names"]["short"],
        "public_name" => response["names"]["display"],
        "legal_form" => response["olf_code"],
        "kveds" => response["activity_kinds"],
        "registration_address" => response["address"],
        "state" => response["state"],
        "updated_by" => Confex.fetch_env!(:core, :system_user)
      }

      changeset = EdrData.changeset(edr_data, data)

      PRMRepo.transaction(fn ->
        if previous_state == 1 && get_change(changeset, :state) do
          LegalEntity
          |> where([le], le.edr_data_id == ^id and le.nhs_verified)
          |> PRMRepo.update_all(set: [nhs_verified: false, nhs_unverified_at: DateTime.utc_now()])
        end

        PRMRepo.update(changeset)
      end)
    end
  end

  defp get_edr_data(id) do
    case @read_prm_repo.get(EdrData, id) do
      nil ->
        Logger.error("Can't get edr data by id #{id}")

      %EdrData{} = edr_data ->
        {:ok, edr_data}
    end
  end

  defp get_legal_entity_from_edr(id) do
    case @rpc_edr_worker.run("edr_api", EdrApi.Rpc, :get_legal_entity_detailed_info, [id]) do
      {:ok, response} ->
        {:ok, response}

      {:error, reason} ->
        Logger.error("Can't get edr data from edr. Reason: #{inspect(reason)}")
    end
  end
end
