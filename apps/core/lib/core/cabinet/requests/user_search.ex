defmodule Core.Cabinet.Requests.UserSearch do
  @moduledoc false

  use Ecto.Schema

  alias Core.Ecto.Base64

  @primary_key false
  embedded_schema do
    field(:signed_content, Base64)
    field(:signed_content_encoding, :string)
  end
end
