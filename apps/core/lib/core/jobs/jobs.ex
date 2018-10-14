defmodule Core.Jobs do
  @moduledoc """
  Kafka Jobs entry
  """

  alias Core.API.Signature
  alias Core.Jobs.LegalEntityMergeJob
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.RelatedLegalEntity
  alias Core.Utils.TypesConverter
  alias Core.Validators.JsonSchema

  def create_merge_legal_entities_job(
        %{signed_content: %{content: content, encoding: encoding}},
        headers
      ) do
    with {:ok, %{"data" => %{"content" => content}}} <- Signature.decode_and_validate(content, encoding, headers),
         :ok <- JsonSchema.validate(:legal_entity_merge_job, content),
         :ok <- validate_merged_id(content["merged_from_legal_entity"]["id"], content["merged_to_legal_entity"]["id"]),
         :ok <- validate_related_legal_entity("from", content),
         :ok <- validate_related_legal_entity("to", content),
         {:ok, legal_entity_from} <- validate_legal_entity("from", content),
         {:ok, legal_entity_to} <- validate_legal_entity("to", content),
         :ok <- validate_legal_entities_type(legal_entity_from, legal_entity_to) do
      create(content, headers)
    end
  end

  defp validate_related_legal_entity(direction, content) do
    where = [
      is_active: true,
      "merged_#{direction}_id": content["merged_#{direction}_legal_entity"]["id"]
    ]

    case LegalEntities.get_related_by(where) do
      %RelatedLegalEntity{} -> {:error, "Merged #{direction} legal entity is in the process of reorganisation itself"}
      _ -> :ok
    end
  end

  defp validate_legal_entity(direction, content) do
    %{"id" => id, "name" => name, "edrpou" => edrpou} = content["merged_#{direction}_legal_entity"]

    with {:ok, legal_entity} <- validate_is_active(direction, id),
         :ok <- validate_processed(direction, id),
         :ok <- validate_name(direction, legal_entity, name),
         :ok <- validate_edrpou(direction, legal_entity, edrpou) do
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

  defp validate_processed(direction, id) do
    field = String.to_atom("merged_#{direction}_id")

    case LegalEntities.get_related_by([{field, id}]) do
      %RelatedLegalEntity{is_active: true} ->
        {:error, "Merged #{direction} legal entity is in the process of reorganisation itself"}

      _ ->
        :ok
    end
  end

  defp validate_name(_direction, %{name: name}, request_name) when name == request_name, do: :ok
  defp validate_name(direction, _, _), do: {:error, "Invalid merged #{direction} legal entity name"}

  defp validate_edrpou(_direction, %{edrpou: edrpou}, request_edrpou) when edrpou == request_edrpou, do: :ok
  defp validate_edrpou(direction, _, _), do: {:error, "Invalid merged #{direction} legal entity edrpou"}

  defp validate_merged_id(from_id, to_id) when from_id != to_id, do: :ok
  defp validate_merged_id(_, _), do: {:error, "Legator and successor of legal entities must be different"}

  defp validate_legal_entities_type(%{type: type_from}, %{type: type_to}) when type_from == type_to, do: :ok
  defp validate_legal_entities_type(_, _), do: {:error, "Legal entity types should be identical"}

  defp create(content, headers) do
    meta = Map.take(content, ~w(merged_from_legal_entity merged_to_legal_entity))
    job_data = Map.put(content, "headers", headers)

    LegalEntityMergeJob
    |> struct(TypesConverter.strings_to_keys(job_data))
    |> LegalEntityMergeJob.produce(meta)
  end
end
