defmodule EHealth.PRM.Divisions.Search do
  @moduledoc false

  use Ecto.Schema

  schema "division_search" do
    field :ids, EHealth.Ecto.CommaParamsUUID
    field :name, :string
    field :type, :string
    field :legal_entity_id, Ecto.UUID
    field :status, :string
  end
end
