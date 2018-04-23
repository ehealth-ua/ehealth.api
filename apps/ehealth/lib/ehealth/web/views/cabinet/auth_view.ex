defmodule EHealth.Web.Cabinet.AuthView do
  @moduledoc false

  use EHealth.Web, :view

  @user ~w(email tax_id)
  @person ~w(first_name last_name birth_date birth_country birth_settlement gender)

  def render("raw.json", %{json: json}) do
    json
  end

  def render("email_validation.json", %{token: token}) do
    %{token: token}
  end

  def render("patient.json", %{patient: %{user: user, patient: person, access_token: token}}) do
    %{user: Map.take(user, @user), patient: Map.take(person, @person), access_token: token}
  end
end
