defmodule EHealth.Web.RegisterEntryView do
  @moduledoc false

  use EHealth.Web, :view

  @fields ~w(
    id
    tax_id
    national_id
    passport
    birth_certificate
    temporary_certificate
    register_id
    status
    inserted_at
    inserted_by
    updated_at
    updated_by
  )a

  def render("index.json", %{register_entries: register_entries}) do
    render_many(register_entries, __MODULE__, "show.json")
  end

  def render("show.json", %{register_entry: register_entry}) do
    Map.take(register_entry, @fields)
  end
end
