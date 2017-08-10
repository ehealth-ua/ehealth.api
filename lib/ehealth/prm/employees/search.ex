defmodule EHealth.PRM.Employees.Search do
  @moduledoc false

  use Ecto.Schema

  schema "employee_search" do
    field :ids, EHealth.Ecto.CommaParamsUUID
    field :party_id, Ecto.UUID
    field :division_id, Ecto.UUID
    field :legal_entity_id, Ecto.UUID
    field :tax_id, :string
    field :edrpou, :string
    field :employee_type, :string
    field :status, :string
    field :starting_after, :string
    field :ending_before, :string
    field :is_active, :boolean
    field :limit, :integer
  end
end
