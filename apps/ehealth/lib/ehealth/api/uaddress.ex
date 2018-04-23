defmodule EHealth.API.UAddress do
  @moduledoc """
  PRM API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.Helpers.MicroserviceBase

  def search_settlements(params \\ %{}, headers \\ []) do
    get!("/settlements", headers, params: params)
  end

  def get_settlement_by_id(id, headers \\ []) do
    get!("/settlements/#{id}", headers)
  end

  def update_settlement(id, data, headers) do
    patch!("/settlements/#{id}", Poison.encode!(%{"settlement" => data}), headers)
  end

  def get_region_by_id(id, headers \\ []) do
    get!("/regions/#{id}", headers)
  end

  def get_district_by_id(id, headers \\ []) do
    get!("/districts/#{id}", headers)
  end
end
