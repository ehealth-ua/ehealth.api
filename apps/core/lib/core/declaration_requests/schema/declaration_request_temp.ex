defmodule Core.DeclarationRequests.DeclarationRequestTemp do
  @moduledoc false

  use Ecto.Schema

  @primary_key {:id, :id, autogenerate: false}
  schema "declaration_requests_temp" do
    field(:last_inserted_at, :naive_datetime)
  end
end
