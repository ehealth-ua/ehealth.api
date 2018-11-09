defmodule EHealth.Web.DivisionView do
  @moduledoc false

  use EHealth.Web, :view
  alias Core.Divisions.Renderer, as: DivisionsRenderer

  def render("index.json", %{divisions: divisions}) do
    render_many(divisions, __MODULE__, "division.json")
  end

  def render("show.json", %{division: division}) do
    render_one(division, __MODULE__, "division.json")
  end

  def render("division.json", %{division: division}) do
    DivisionsRenderer.render("division.json", division)
  end

  def render("division_addresses.json", %{address: address}) do
    DivisionsRenderer.render("division_addresses.json", address)
  end

  def render("division_short.json", %{"division" => division}) do
    Map.take(division, ~w(id name type status))
  end

  def render("division_short.json", %{division: division}) do
    Map.take(division, ~w(id name type status)a)
  end

  def render("division_short.json", _), do: %{}
end
