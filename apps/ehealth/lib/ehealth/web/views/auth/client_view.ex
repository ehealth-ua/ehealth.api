defmodule EHealth.Web.ClientView do
  use EHealth.Web, :view

  @fields ~w(
    id
    name
    settings
    is_blocked
    block_reason
    user_id
    client_type_id
    client_type_name
    inserted_at
    updated_at
  )

  def render("index.json", %{clients: clients}) do
    render_many(clients, __MODULE__, "client.json")
  end

  def render("show.json", %{client: client}) do
    render_one(client, __MODULE__, "client.json")
  end

  def render("client.json", %{client: client}) do
    Map.take(client, @fields)
  end
end
