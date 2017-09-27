defmodule EHealth.Web.MedicalProgramView do
  @moduledoc false

  use EHealth.Web, :view

  def render("index.json", %{medical_programs: medical_programs}) do
    render_many(medical_programs, __MODULE__, "show.json")
  end

  def render("show.json", %{medical_program: medical_program}) do
    Map.take(medical_program, ~w(
      id
      name
      is_active
      inserted_at
      inserted_by
      updated_at
      updated_by
    )a)
  end
end
