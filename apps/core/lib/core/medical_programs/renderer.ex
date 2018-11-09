defmodule Core.MedicalPrograms.Renderer do
  @moduledoc false

  alias Core.MedicalPrograms.MedicalProgram

  def render("show.json", %MedicalProgram{} = medical_program) do
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
