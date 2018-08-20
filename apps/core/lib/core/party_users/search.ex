defmodule Core.PartyUsers.Search do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:party_id, :string)
    field(:user_id, :string)
  end
end
