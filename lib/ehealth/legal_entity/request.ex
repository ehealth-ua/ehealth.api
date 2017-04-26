defmodule EHealth.LegalEntity.Request do
  @moduledoc false

  use Ecto.Schema

  schema "legal_entity_request" do
    field :signed_legal_entity_request, :string
    field :signed_content_encoding, :string
  end
end
