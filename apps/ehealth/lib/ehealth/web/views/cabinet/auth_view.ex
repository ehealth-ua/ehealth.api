defmodule EHealth.Web.Cabinet.AuthView do
  @moduledoc false

  use EHealth.Web, :view

  def render("raw.json", %{json: json}) do
    json
  end

  def render("email_validation.json", %{token: token}) do
    %{token: token}
  end

  def render("patient.json", %{patient: patient}) do
    patient
  end
end
