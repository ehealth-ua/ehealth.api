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
      no_tax_id
    )a)
  end

  def render("party_private.json", %{party: party}) do
    Map.take(party, ~w(
      id
      first_name
      last_name
      second_name
      phones
      email
      no_tax_id
    )a)
  end

  def render("party_short.json", %{"party" => party}) do
    Map.take(party, ~w(
      id
      first_name
      last_name
      second_name
      email
      phones
      tax_id
      no_tax_id
    ))
  end
  def render("party_short.json", _), do: %{}
end
