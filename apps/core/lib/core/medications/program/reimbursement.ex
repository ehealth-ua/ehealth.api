defmodule Core.Medications.Program.Reimbursement do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  @type_fixed "FIXED"

  def type(:fixed), do: @type_fixed

  @primary_key false
  embedded_schema do
    field(:type, :string, null: false)
    field(:reimbursement_amount, :float, null: false)
  end

  def changeset(%__MODULE__{} = entity, params) do
    fields = __MODULE__.__schema__(:fields)

    entity
    |> cast(params, fields)
    |> validate_required(fields)
    |> validate_inclusion(:type, [@type_fixed])
    |> validate_number(:reimbursement_amount, greater_than_or_equal_to: 0)
  end
end
