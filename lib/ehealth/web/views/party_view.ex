defmodule EHealth.Web.PartyView do
  @moduledoc false

  use EHealth.Web, :view

  def render("show.json", %{party: party}) do
    Map.take(party, ~w(
      id
      first_name
      last_name
      birth_date
      phones
      birth_settlement
    )a)
  end

  def render("party_short.json", %{"party" => party}) do
    %{
      "id" => Map.get(party, "id"),
      "first_name" => Map.get(party, "first_name"),
      "last_name" => Map.get(party, "last_name"),
      "second_name" => Map.get(party, "second_name"),
      "email" => Map.get(party, "email"),
      "phones" => Map.get(party, "phones"),
      "tax_id" => Map.get(party, "tax_id")
    }
  end
  def render("party_short.json", _), do: %{}
end
