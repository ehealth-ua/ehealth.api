defmodule EHealth.LegalEntities.Search do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "legal_entity_search" do
    field :ids, EHealth.Ecto.CommaParamsUUID
    field :is_active, :boolean
    field :nhs_verified, :boolean
    field :edrpou, :string
    field :type, :string
    field :owner_property_type, :string
    field :legal_form, :string
    field :status, :string
    field :settlement_id, Ecto.UUID
    field :created_by_mis_client_id, Ecto.UUID
    field :mis_verified, :string
  end
end
