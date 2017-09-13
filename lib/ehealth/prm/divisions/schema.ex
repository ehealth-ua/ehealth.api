defmodule EHealth.PRM.Divisions.Schema do
  @moduledoc false

  use Ecto.Schema

  @status_active "ACTIVE"
  @status_inactive "INACTIVE"

  def status(:active), do: @status_active
  def status(:inactive), do: @status_inactive

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "divisions" do
    field :email, :string
    field :external_id, :string
    field :mountain_group, :boolean, null: false
    field :name, :string
    field :addresses, {:array, :map}
    field :phones, {:array, :map}
    field :type, :string
    field :status, :string, null: false
    field :is_active, :boolean, default: false
    field :location, Geo.Geometry

    belongs_to :legal_entity, EHealth.PRM.LegalEntities.Schema, type: Ecto.UUID

    timestamps()
  end
end
