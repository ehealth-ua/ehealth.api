defmodule GraphQL.Jobs do
  @moduledoc """
  Kafka Jobs entry
  """

  import Core.API.Helpers.Connection, only: [get_consumer_id: 1]

  alias Absinthe.Relay.Node
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.RelatedLegalEntity
  alias Core.Utils.TypesConverter
  alias Core.Validators.JsonSchema
  alias Core.Validators.Signature
  alias GraphQL.Jobs.LegalEntityMergeJob

  @status_active LegalEntity.status(:active)
  @type_msp LegalEntity.type(:msp)

  @merge_legal_entities_type 200

  def type(:merge_legal_entities), do: @merge_legal_entities_type

  def create_merge_legal_entities_job(%{signed_content: %{content: encoded_content, encoding: encoding}}, headers) do
    user_id = get_consumer_id(headers)

    with {:ok, %{"content" => content, "signers" => [signer]}} <-
           Signature.validate(encoded_content, encoding, headers),
         :ok <- Signature.check_drfo(signer, user_id, "merge_legal_entities"),
         :ok <- JsonSchema.validate(:legal_entity_merge_job, content),
         :ok <- validate_merged_id(content["merged_from_legal_entity"]["id"], content["merged_to_legal_entity"]["id"]),
         :ok <- validate_is_merged(:from, content),
         :ok <- validate_is_merged(:to, content),
         {:ok, legal_entity_from} <- validate_legal_entity("from", content),
         {:ok, legal_entity_to} <- validate_legal_entity("to", content),
         :ok <- validate_legal_entities_type(legal_entity_from, legal_entity_to),
         :ok <- create(content, encoded_content, headers) do
      :ok
    else
      {:error, {code, reason}} when is_atom(code) ->
        {:error, reason}

      {:job_exists, id} ->
        id = Node.to_global_id("LegalEntityMergeJob", id)
        {:error, "Merge Legal Entity job already created with id #{id}"}

      err ->
        err
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
      %RelatedLegalEntity{} -> {:error, message}
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
      %LegalEntity{is_active: false} -> {:error, "Merged #{direction} legal entity must be active"}
      _ -> {:error, "Merged #{direction} legal entity not found"}
    end
  end

  defp validate_name(_direction, %{name: name}, request_name) when name == request_name, do: :ok
  defp validate_name(direction, _, _), do: {:error, "Invalid merged #{direction} legal entity name"}

  defp validate_edrpou(_direction, %{edrpou: edrpou}, request_edrpou) when edrpou == request_edrpou, do: :ok
  defp validate_edrpou(direction, _, _), do: {:error, "Invalid merged #{direction} legal entity edrpou"}

  defp validate_status(_direction, %{status: @status_active}), do: :ok
  defp validate_status(direction, _), do: {:error, "Merged #{direction} legal entity must be active"}

  defp validate_merged_id(from_id, to_id) when from_id != to_id, do: :ok
  defp validate_merged_id(_, _), do: {:error, "Legator and successor of legal entities must be different"}

  defp validate_legal_entities_type(%{type: @type_msp}, %{type: @type_msp}), do: :ok
  defp validate_legal_entities_type(_, _), do: {:error, "Invalid legal entity type"}

  defp create(content, encoded_content, headers) do
    meta = Map.take(content, ~w(merged_from_legal_entity merged_to_legal_entity))
    job_data = Map.merge(content, %{"headers" => headers, "signed_content" => encoded_content})

    LegalEntityMergeJob
    |> struct(TypesConverter.strings_to_keys(job_data))
    |> LegalEntityMergeJob.produce(meta, type: @merge_legal_entities_type)
  end
end
