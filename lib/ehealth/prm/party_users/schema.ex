defmodule EHealth.PRM.PartyUsers.Schema do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "party_users" do
    field :user_id, Ecto.UUID

    belongs_to :party, EHealth.PRM.Parties.Schema, type: Ecto.UUID

    timestamps()
  end
end
