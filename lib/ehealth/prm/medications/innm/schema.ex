defmodule EHealth.PRM.Medications.INNM.Schema do
  @moduledoc false
  use Ecto.Schema

  @derive {Poison.Encoder, except: [:__meta__]}

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "innms" do
    field :sctid, :string
    field :name, :string
    field :name_original, :string
    field :is_active, :boolean, default: true
    field :inserted_by, Ecto.UUID
    field :updated_by, Ecto.UUID

    timestamps()
  end
end
