defmodule Core.API.UAddress do
  @moduledoc """
  PRM API client
  """

  use Core.API.Helpers.MicroserviceBase

  @behaviour Core.API.UAddressesBehaviour

  def search_settlements(params \\ %{}, headers \\ []) do
    get!("/settlements", headers, params: params)
  end

  def get_settlement_by_id(id, headers \\ []) do
    get!("/settlements/#{id}", headers)
  end

  def update_settlement(id, data, headers) do
    patch!("/settlements/#{id}", Jason.encode!(%{"settlement" => data}), headers)
  end

  def get_region_by_id(id, headers \\ []) do
    get!("/regions/#{id}", headers)
  end

  def get_district_by_id(id, headers \\ []) do
    get!("/districts/#{id}", headers)
  end

  def validate_addresses(addresses, headers \\ []) when is_list(addresses) do
    post!("/validate_address", Jason.encode!(%{"addresses" => addresses}), headers)
  end
end
