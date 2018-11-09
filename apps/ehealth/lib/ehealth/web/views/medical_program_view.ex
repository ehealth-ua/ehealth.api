defmodule EHealth.Web.MedicalProgramView do
  @moduledoc false

  use EHealth.Web, :view
  alias Core.MedicalPrograms.Renderer, as: MedicalProgramsRenderer

  def render("index.json", %{medical_programs: medical_programs}) do
    render_many(medical_programs, __MODULE__, "show.json")
  end

  def render("show.json", %{medical_program: medical_program}) do
    MedicalProgramsRenderer.render("show.json", medical_program)
  end
end
