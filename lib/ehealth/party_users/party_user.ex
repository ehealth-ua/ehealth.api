defmodule EHealth.PartyUsers.PartyUser do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "party_users" do
    field :user_id, Ecto.UUID

    belongs_to :party, EHealth.Parties.Party, type: Ecto.UUID

    timestamps()
  end
end
