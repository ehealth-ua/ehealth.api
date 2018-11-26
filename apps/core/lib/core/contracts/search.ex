defmodule Core.Contracts.Search do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias Core.Ecto.CommaParamsUUID
  alias Ecto.UUID

  @primary_key false
  embedded_schema do
    field(:id, UUID)
    field(:ids, CommaParamsUUID)
    field(:date_from_start_date, :date)
    field(:date_to_start_date, :date)
    field(:date_from_end_date, :date)
    field(:date_to_end_date, :date)
    field(:type, :string)
    field(:status, :string)
    field(:edrpou, :string)
    field(:legal_entity_id, UUID)
    field(:contractor_legal_entity_id, UUID)
    field(:contractor_owner_id, UUID)
    field(:nhs_signer_id, UUID)
    field(:contract_number, :string)
    field(:is_suspended, :boolean)
    field(:page, :integer)
    field(:page_size, :integer)
  end

  def changeset(params) do
    %__MODULE__{}
    |> cast(params, __MODULE__.__schema__(:fields))
    |> uppercase_status()
  end

  defp uppercase_status(%{changes: %{status: _}} = changeset), do: update_change(changeset, :status, &String.upcase(&1))
  defp uppercase_status(changeset), do: changeset
end
