defmodule EHealth.GlobalParameters.GlobalParameter do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "global_parameters" do
    field :parameter, :string
    field :value, :string
    field :inserted_by, Ecto.UUID
    field :updated_by, Ecto.UUID

    timestamps()
  end
end
