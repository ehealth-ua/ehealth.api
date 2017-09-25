defmodule EHealth.Web.MedicalProgramView do
  @moduledoc false

  def render("show.json", %{medical_program: medical_program}) do
    Map.take(medical_program, ~w(id name)a)
  end
end
