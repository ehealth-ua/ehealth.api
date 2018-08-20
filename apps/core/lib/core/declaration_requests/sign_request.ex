defmodule Core.DeclarationRequests.SignRequest do
  @moduledoc false

  use Ecto.Schema

  schema "declaration_sign_request" do
    field(:signed_declaration_request, :string)
    field(:signed_content_encoding, :string)
  end
end
