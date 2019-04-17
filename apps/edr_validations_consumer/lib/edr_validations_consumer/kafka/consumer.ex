defmodule EdrValidationsConsumer.Kafka.Consumer do
  @moduledoc false

  require Logger
  alias Core.LegalEntities
  alias Core.LegalEntities.EdrVerification
  alias Core.LegalEntities.LegalEntity
  alias Core.PRMRepo
  alias Ecto.Changeset
  import Ecto.Changeset

  @rpc_worker Application.get_env(:core, :rpc_worker)
  @rpc_edr_worker Application.get_env(:core, :rpc_edr_worker)
  @edr_status_ok EdrVerification.status(:verified)
  @edr_status_error EdrVerification.status(:error)

  def handle_message(%{offset: offset, value: message}) do
    value = :erlang.binary_to_term(message)
    Logger.debug(fn -> "message: " <> inspect(value) end)
    Logger.info(fn -> "offset: #{offset}" end)
    :ok = consume(value)
  end

  def consume(%{"legal_entity_id" => id}) do
    changes = %EdrVerification{legal_entity_id: id}

    case get_legal_entity(id, changes) do
      {:ok, legal_entity} ->
        do_consume(legal_entity, changes)
        :ok

      %Changeset{} = changeset ->
        insert_edr_validation(changeset)
    end
  end

  def consume(value) do
    Logger.warn("Invalid message #{inspect(value)}")
    :ok
  end

  defp do_consume(%LegalEntity{} = legal_entity, changes) do
    with {:ok, edr_legal_entity} <- get_edr_legal_entity(legal_entity, changes),
         edr_data <- get_edr_data(edr_legal_entity),
         changes <- EdrVerification.changeset(changes, %{"status_code" => 200, "edr_data" => edr_data}),
         registration_address <- Enum.find(legal_entity.addresses, &(Map.get(&1, "type") == "REGISTRATION")) || %{},
         {:ok, settlement} <- get_settlement(registration_address["settlement_id"], changes) do
      legal_entity_data = %{
        "name" => legal_entity.name,
        "legal_form" => legal_entity.legal_form,
        "address" => Map.get(settlement, :koatuu)
      }

      changes
      |> EdrVerification.changeset(%{
        "edr_state" => edr_legal_entity["state"],
        "edr_status" => get_edr_status(edr_legal_entity, edr_data, legal_entity_data),
        "legal_entity_data" => legal_entity_data
      })
      |> insert_edr_validation(legal_entity)
    else
      %Changeset{} = changeset ->
        insert_edr_validation(changeset, legal_entity)
    end
  end

  defp get_legal_entity(id, changes) do
    case LegalEntities.get_by_id(id) do
      %LegalEntity{} = legal_entity ->
        {:ok, legal_entity}

      _ ->
        EdrVerification.changeset(changes, %{
          "error_message" => "Legal entity not found"
        })
    end
  end

  def get_settlement(nil, changes) do
    EdrVerification.changeset(changes, %{
      "error_message" => "Invalid settlement"
    })
  end

  def get_settlement(id, changes) do
    with {:ok, settlement} <- @rpc_worker.run("uaddresses_api", Uaddresses.Rpc, :settlement_by_id, [id]) do
      {:ok, settlement}
    else
      _ ->
        EdrVerification.changeset(changes, %{
          "error_message" => "Invalid settlement"
        })
    end
  end

  defp get_edr_status(%{"state" => 1}, edr_data, legal_entity_data) do
    legal_entity_address = legal_entity_data["address"]

    same_address? =
      legal_entity_address &&
        String.starts_with?(edr_data["address"], String.replace_trailing(legal_entity_address, "0", ""))

    if Map.drop(edr_data, ~w(address)) == Map.drop(legal_entity_data, ~w(address)) and same_address? do
      EdrVerification.status(:verified)
    else
      EdrVerification.status(:error)
    end
  end

  defp get_edr_status(_, _, _) do
    EdrVerification.status(:error)
  end

  defp insert_edr_validation(changeset) do
    with {:ok, _} <- PRMRepo.insert(changeset) do
      :ok
    end
  end

  defp insert_edr_validation(changeset, legal_entity) do
    transaction =
      PRMRepo.transaction(fn ->
        edr_verified =
          case get_change(changeset, :edr_status) do
            @edr_status_ok -> true
            @edr_status_error -> false
            _ -> nil
          end

        if get_change(changeset, :edr_status) do
          legal_entity
          |> cast(%{"edr_verified" => edr_verified}, ~w(edr_verified)a)
          |> PRMRepo.update!()

          PRMRepo.insert!(changeset)
        else
          PRMRepo.insert!(changeset)
        end
      end)

    with {:ok, _} <- transaction do
      :ok
    end
  end

  defp get_edr_legal_entity(%LegalEntity{edrpou: edrpou}, changes) do
    cond do
      Regex.match?(~r/^[0-9]{8,10}$/, edrpou) ->
        "edr_api"
        |> @rpc_edr_worker.run(EdrApi.Rpc, :legal_entity_by_code, [edrpou])
        |> process_edr_response(changes)

      Regex.match?(~r/^((?![ЫЪЭЁ])([А-ЯҐЇІЄ])){2}[0-9]{6}$/u, edrpou) ->
        "edr_api"
        |> @rpc_edr_worker.run(EdrApi.Rpc, :legal_entity_by_passport, [edrpou])
        |> process_edr_response(changes)

      true ->
        EdrVerification.changeset(changes, %{
          "error_message" => "Invalid EDRPOU (DRFO)"
        })
    end
  end

  defp process_edr_response({:ok, edr_legal_entity}, _), do: {:ok, edr_legal_entity}

  defp process_edr_response({:error, reason}, changes) when is_binary(reason) do
    EdrVerification.changeset(changes, %{
      "error_message" => reason
    })
  end

  defp process_edr_response({:error, :timeout}, changes) do
    EdrVerification.changeset(changes, %{
      "status_code" => 504,
      "edr_status" => EdrVerification.status(:error)
    })
  end

  defp process_edr_response({:error, %{"status_code" => 400, "body" => body}}, changes) do
    EdrVerification.changeset(changes, %{
      "status_code" => 400,
      "edr_status" => EdrVerification.status(:error),
      "error_message" => body
    })
  end

  defp process_edr_response({:error, %{"status_code" => status_code, "body" => body}}, changes) do
    EdrVerification.changeset(changes, %{
      "status_code" => status_code,
      "error_message" => body
    })
  end

  defp get_edr_data(edr_legal_entity) do
    %{
      "name" => edr_legal_entity["names"]["display"],
      "legal_form" => edr_legal_entity["olf_code"],
      "address" => edr_legal_entity["address"]["parts"]["atu_code"]
    }
  end
end
