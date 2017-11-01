defmodule EHealth.Web.PartyUserView do
  @moduledoc false

  use EHealth.Web, :view

  def render("index.json", %{party_users: party_users}) do
    render_many(party_users, __MODULE__, "show.json", as: :party_user)
  end

  def render("show.json", %{party_user: party_user}) do
    %{
      id: party_user.id,
      user_id: party_user.user_id,
      party_id: party_user.party_id,
      first_name: party_user.party.first_name,
      second_name: party_user.party.second_name,
      last_name: party_user.party.last_name,
      birth_date: party_user.party.birth_date,
      inserted_at: party_user.inserted_at,
      updated_at: party_user.updated_at
    }
  end
end
