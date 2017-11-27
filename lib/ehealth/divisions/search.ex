defmodule EHealth.Divisions.Search do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "division_search" do
    field :ids, EHealth.Ecto.CommaParamsUUID
    field :name, :string
    field :type, :string
    field :legal_entity_id, Ecto.UUID
    field :status, :string
  end
end
