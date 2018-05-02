defmodule EHealth.ContractRequests.Search do
  @moduledoc false

  use Ecto.Schema
  import Ecto.Changeset

  alias EHealth.Ecto.StringLike

  @primary_key false
  embedded_schema do
    field(:id, Ecto.UUID)
    field(:contractor_legal_entity_id, Ecto.UUID)
    field(:contractor_owner_id, Ecto.UUID)
    field(:nhs_signer_id, Ecto.UUID)
    field(:issue_city, StringLike)
    field(:status, :string)
    field(:contract_number, :string)
  end

  def changeset(params) do
    %__MODULE__{}
    |> cast(params, __MODULE__.__schema__(:fields))
    |> uppercase_status()
  end

  defp uppercase_status(%{changes: %{status: _}} = changeset), do: update_change(changeset, :status, &String.upcase(&1))
  defp uppercase_status(changeset), do: changeset
end
