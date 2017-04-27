defmodule EHealth.LegalEntity.API do
  @moduledoc """
  The boundary for the LegalEntity system.
  """

  alias EHealth.API.PRM
  alias EHealth.LegalEntity.Validator

  def create_legal_entity(attrs, headers) do
    attrs
    |> Validator.decode_and_validate()
    |> process_request(headers)
  end

  def process_request({:ok, %{"edrpou" => edrpou} = request_legal_entity}, headers) do
    edrpou
    |> PRM.get_legal_entity_by_edrpou(headers)
    |> create_or_update(request_legal_entity, headers)
  end
  def process_request(err, _consumer_id), do: err

  @doc """
  The creation or updating of Legal Entity depends on the existing Legal Entity in PRM database.
  """
  def create_or_update({:ok, %{"data" => []}}, request_legal_entity, headers) do
    consumer_id = get_consumer_id(headers)

    request_legal_entity
    |> Map.merge(%{"status" => "new", "inserted_by" => consumer_id, "updated_by" => consumer_id})
    |> PRM.create_legal_entity(headers)
  end

  def create_or_update({:ok, %{"data" => [legal_entity]}}, request_legal_entity, headers) do
    request_legal_entity
    |> Map.drop(["edrpou", "kveds"]) # filter immutable data
    |> Map.put("updated_by", get_consumer_id(headers))
    |> PRM.update_legal_entity(Map.fetch!(legal_entity, "id"), headers)
  end

  def create_or_update({:error, _} = err, _, _), do: err

  def get_consumer_id(headers) do
    list = for {k, v} <- headers, k == "x-consumer-id", do: v
    List.first(list)
  end
end
