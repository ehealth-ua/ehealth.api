defmodule EHealth.Cabinet.UserSearchRequest do
  @moduledoc false

  use Ecto.Schema

  @primary_key false
  schema "user_search_request" do
    field(:tax_id, :string)
  end
end
