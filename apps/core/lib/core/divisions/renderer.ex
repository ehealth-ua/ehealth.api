defmodule Core.Divisions.Renderer do
  @moduledoc false

  alias Core.Divisions.Division
  alias Core.Divisions.DivisionAddress

  def render("division.json", %Division{} = division) do
    division
    |> Map.take(~w(
          id
          name
          type
          mountain_group
          phones
          email
          external_id
          legal_entity_id
          status
          working_hours
          dls_id
          dls_verified
        )a)
    |> Map.merge(%{
      location: to_coordinates(division.location),
      addresses: Enum.map(division.addresses, &render("division_addresses.json", &1))
    })
  end

  def render("division_addresses.json", %DivisionAddress{} = address) do
    Map.take(address, ~w(
          apartment
          area
          building
          country
          region
          settlement
          settlement_id
          settlement_type
          street
          street_type
          type
          zip
        )a)
  end

  defp to_coordinates(%Geo.Point{coordinates: {lng, lat}}) do
    %{
      longitude: lng,
      latitude: lat
    }
  end

  defp to_coordinates(field), do: field
end
