defmodule EHealth.Web.RegisterView do
  @moduledoc false

  use EHealth.Web, :view

  @fields ~w(
    id
    file_name
    qty
    type
    status
    inserted_at
    inserted_by
    updated_at
    updated_by
  )a

  def render("index.json", %{registers: registers}) do
    render_many(registers, __MODULE__, "show.json")
  end

  def render("show.json", %{register: register}) do
    Map.take(register, @fields)
  end
end
