defmodule EHealth.Web.PartyView do
  @moduledoc false

  use EHealth.Web, :view

  def render("show.json", %{party: party}) do
    party
    |> Map.take(~w(
      id
      first_name
      last_name
      birth_date
      birth_settlement
      no_tax_id
    )a)
    |> Map.put(:phones, render_many(Map.get(party, :phones, []), __MODULE__, "phone.json", as: :phone))
  end

  def render("party_private.json", %{party: party}) do
    party
    |> Map.take(~w(
      id
      first_name
      last_name
      second_name
      email
      no_tax_id
    )a)
    |> Map.put(:phones, render_many(Map.get(party, :phones, []), __MODULE__, "phone.json", as: :phone))
  end

  def render("party_short.json", %{"party" => party}) do
    party
    |> Map.take(~w(
      id
      first_name
      last_name
      second_name
      email
      tax_id
      no_tax_id
    ))
    |> Map.put(:phones, render_many(Map.get(party, :phones, []), __MODULE__, "phone.json", as: :phone))
  end

  def render("party_short.json", _), do: %{}

  def render("phone.json", %{phone: phone}) do
    Map.take(phone, ~w(type number)a)
  end
end
