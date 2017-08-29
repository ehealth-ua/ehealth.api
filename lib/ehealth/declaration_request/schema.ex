defmodule EHealth.DeclarationRequest do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  @derive {Poison.Encoder, except: [:__meta__]}

  @status_new "NEW"
  @status_signed "SIGNED"
  @status_cancelled "CANCELLED"
  @status_rejected "REJECTED"
  @status_approved "APPROVED"

  def status(:new), do: @status_new
  def status(:signed), do: @status_signed
  def status(:cancelled), do: @status_cancelled
  def status(:rejected), do: @status_rejected
  def status(:approved), do: @status_approved

  schema "declaration_requests" do
    field :data, :map
    field :status, :string
    field :authentication_method_current, :map
    field :documents, {:array, :map}
    field :printout_content, :string
    field :inserted_by, Ecto.UUID
    field :updated_by, Ecto.UUID
    field :declaration_id, Ecto.UUID

    timestamps()
  end
end
