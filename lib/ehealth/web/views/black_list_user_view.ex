defmodule EHealth.Web.BlackListUserView do
  @moduledoc false

  use EHealth.Web, :view

  @fields ~w(
    id
    tax_id
    is_active
    inserted_at
    inserted_by
    updated_at
    updated_by
  )a

  @party_fields ~w(
    id
    first_name
    last_name
    second_name
    birth_date
  )a

  def render("index.json", %{black_list_users: black_list_users}) do
    render_many(black_list_users, __MODULE__, "show.json")
  end

  def render("show.json", %{black_list_user: black_list_user}) do
    parties = black_list_user.parties || []
    black_list_user
    |> Map.take(@fields)
    |> Map.put(:parties, render_many(parties, __MODULE__, "party.json", as: :party))
  end

  def render("party.json", %{party: party}) do
    Map.take(party, @party_fields)
  end

end
