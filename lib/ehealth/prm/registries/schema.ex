defmodule EHealth.PRM.Registries.Schema do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "ukr_med_registries" do
    field :name, :string
    field :edrpou, :string
    field :inserted_by, Ecto.UUID
    field :updated_by, Ecto.UUID

    timestamps()
  end
end
