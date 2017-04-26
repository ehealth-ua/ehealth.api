defmodule EHealth.LegalEntity.API do
  @moduledoc """
  The boundary for the LegalEntity system.
  """

  alias EHealth.API.PRM
  alias EHealth.LegalEntity.Validator

  require Logger

  def create_legal_entity(attrs) do
    attrs
    |> Validator.decode_and_validate()
    |> process_request()
  end

  def process_request({:ok, %{"edrpou" => edrpou} = request_legal_entity}) do
    edrpou
    |> PRM.get_legal_entity_by_edrpou()
    |> create_or_update(request_legal_entity)
  end
  def process_request(err), do: err

  @doc """
  The creation or updating of Legal Entity depends on the existing Legal Entity in PRM database.
  """
  def create_or_update({:ok, []}, request_legal_entity) do
    PRM.create_legal_entity(request_legal_entity)
  end

  def create_or_update({:ok, [legal_entity]}, request_legal_entity) do
    request_legal_entity
    |> filter_update_legal_entity_data()
    |> PRM.update_legal_entity(Map.fetch!(legal_entity, "id"))
  end

  def create_or_update(err, _request_legal_entity), do: err

  def filter_update_legal_entity_data(data) do
    Map.drop(data, ["edrpou", "kved"])
  end
end
