defmodule EHealth.Web.Cabinet.AppsView do
  @moduledoc false

  use EHealth.Web, :view

  def render("app_show.json", %{app: app}) do
    Map.take(app, ~w(
      id
      user_id
      client_name
      client_id
      scope
      created_at
      updated_at
      ))
  end

  def render("client.json", %{client: client}) do
    Map.take(client, ~w(
    id
    name
    secret
    redirect_uri
    settings
    priv_settings
    is_blocked
    block_reason
    user_id
    client_type_id
    inserted_at
    updated_at
    client_type_name
  ))
  end

  def render("app_index.json", %{apps: apps}) do
    render_many(apps, __MODULE__, "app_show.json", as: :app)
  end
end
