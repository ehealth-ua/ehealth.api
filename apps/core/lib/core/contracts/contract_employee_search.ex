defmodule Core.Contracts.ContractEmployeeSearch do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.UUID

  @primary_key false
  embedded_schema do
    field(:division_id, UUID)
    field(:employee_id, UUID)
    field(:is_active, :boolean)
    field(:page, :integer)
    field(:page_size, :integer)
  end

  def changeset(params) do
    cast(%__MODULE__{}, params, __MODULE__.__schema__(:fields))
  end
end
