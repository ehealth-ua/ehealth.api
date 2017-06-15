defmodule EHealth.DeclarationRequest do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :binary_id, autogenerate: true}

  @derive {Poison.Encoder, except: [:__meta__]}

  schema "declaration_requests" do
    field :data, :map
    field :status, :string
    field :authentication_method_current, :map
    field :documents, {:array, :map}
    field :printout_content, :string
    field :inserted_by, Ecto.UUID
    field :updated_by, Ecto.UUID

    timestamps()
  end
end
