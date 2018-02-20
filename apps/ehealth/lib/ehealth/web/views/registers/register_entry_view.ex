defmodule EHealth.Web.RegisterEntryView do
  @moduledoc false

  use EHealth.Web, :view

  @fields ~w(
    id
    document_type
    document_number
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
    register_entry
    |> Map.take(@fields)
    |> render_register(register_entry)
  end

  def render_register(view, register_entry) do
    Map.merge(view, %{
      type: register_entry.register.type,
      file_name: register_entry.register.file_name
    })
  end
end
