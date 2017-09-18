defmodule EHealth.PRM.Medication do
  @moduledoc false
  use Ecto.Schema

  @derive {Poison.Encoder, except: [:__meta__]}

  @type_innm "INNM"
  @type_medication "MEDICATION"

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "medications" do
    field :name, :string
    field :form, :string
    field :type, :string
    field :code_atc, :string
    field :certificate, :string
    field :certificate_expired_at, :date
    field :container, :map
    field :ingredients, {:array, :map}
    field :manufacturer, :map
    field :package_qty, :integer
    field :package_min_qty, :integer
    field :is_active, :boolean, default: true
    field :inserted_by, Ecto.UUID
    field :updated_by, Ecto.UUID

    timestamps()
  end

  def type(:innm), do: @type_innm
  def type(:medication), do: @type_medication

end
