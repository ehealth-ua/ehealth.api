defmodule EHealth.BlackListUsers.Search do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "party_search" do
    field :id, Ecto.UUID
    field :tax_id, :string
    field :is_active, :boolean
  end
end
