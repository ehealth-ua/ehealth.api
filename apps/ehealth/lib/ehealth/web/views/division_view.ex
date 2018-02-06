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
    %{
      id: division.id,
      name: division.name,
      type: division.type,
      mountain_group: division.mountain_group,
      addresses: division.addresses,
      phones: division.phones,
      email: division.email,
      external_id: division.external_id,
      legal_entity_id: division.legal_entity_id,
      status: division.status,
      location: to_coordinates(division.location),
      working_hours: division.working_hours
    }
  end

  def render("division_short.json", %{"division" => division}) do
    %{
      "id" => Map.get(division, "id"),
      "name" => Map.get(division, "name"),
      "type" => Map.get(division, "type"),
      "status" => Map.get(division, "status")
    }
  end

  def render("division_short.json", %{division: division}) do
    %{
      "id" => division.id,
      "name" => division.name,
      "type" => division.type,
      "status" => division.status
    }
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
