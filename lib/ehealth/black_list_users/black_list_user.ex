defmodule EHealth.BlackListUsers.BlackListUser do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "black_list_users" do
    field :tax_id, :string
    field :is_active, :boolean, default: true
    field :updated_by, Ecto.UUID
    field :inserted_by, Ecto.UUID

    has_many :parties, EHealth.Parties.Party, foreign_key: :tax_id, references: :tax_id

    timestamps()
  end
end
