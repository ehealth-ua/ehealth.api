defmodule EHealth.Cabinet.Requests.UserSearch do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  embedded_schema do
    field(:tax_id, :string)
  end
end
