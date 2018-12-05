defmodule Core.Parties.Renderer do
  @moduledoc false

  alias Core.Parties.Party
  alias Core.Parties.Phone

  def render("show.json", %Party{} = party) do
    party
    |> Map.take(~w(
      id
      first_name
      last_name
      birth_date
      birth_settlement
      no_tax_id
    )a)
    |> Map.put(:phones, Enum.map(Map.get(party, :phones, []), &render("phone.json", &1)))
  end

  def render("party_private.json", %Party{} = party) do
    party
    |> Map.take(~w(
      id
      first_name
      last_name
      second_name
      email
      no_tax_id
    )a)
    |> Map.put(:phones, Enum.map(Map.get(party, :phones, []), &render("phone.json", &1)))
  end

  def render("phone.json", %Phone{} = phone) do
    Map.take(phone, ~w(type number)a)
  end
end
