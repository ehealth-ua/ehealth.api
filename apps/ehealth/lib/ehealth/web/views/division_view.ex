defmodule EHealth.Web.DivisionView do
  @moduledoc false

  use EHealth.Web, :view

  def render("index.json", %{divisions: divisions}) do
    render_many(divisions, __MODULE__, "division.json")
  end

  def render("show.json", %{division: division}) do
    render_one(division, __MODULE__, "division.json")
  end

  def render("division.json", %{division: division}) do
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
        )a)
    |> Map.put(:location, to_coordinates(division.location))
    |> Map.put(
      :addresses,
      render_many(division.addresses, __MODULE__, "division_addresses.json", as: :address)
    )
  end

  def render("division_addresses.json", %{address: address}) do
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

  def render("division_short.json", %{"division" => division}) do
    Map.take(division, ~w(id name type status))
  end

  def render("division_short.json", %{division: division}) do
    Map.take(division, ~w(id name type status)a)
  end

  def render("division_short.json", _), do: %{}

  def to_coordinates(%Geo.Point{coordinates: {lng, lat}}) do
    %{
      longitude: lng,
      latitude: lat
    }
  end

  def to_coordinates(field), do: field
end
