defmodule EHealth.Employees.Search do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "employee_search" do
    field :ids, EHealth.Ecto.CommaParamsUUID
    field :party_id, Ecto.UUID
    field :division_id, Ecto.UUID
    field :legal_entity_id, Ecto.UUID
    field :tax_id, :string
    field :edrpou, :string
    field :employee_type, :string
    field :status, :string
    field :is_active, :boolean
  end
end
