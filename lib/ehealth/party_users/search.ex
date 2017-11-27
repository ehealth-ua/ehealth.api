defmodule EHealth.PartyUsers.Search do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "party_user_search" do
    field :party_id, :string
    field :user_id, :string
  end
end
