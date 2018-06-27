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

  def render("authentication_factors_list.json", %{authentication_factors: authentication_factors}) do
    render_many(authentication_factors, __MODULE__, "authentication_factor.json", as: :authentication_factor)
  end

  def render("authentication_factor.json", %{authentication_factor: authentication_factor}) do
    Map.take(authentication_factor, ~w(id type factor is_active user_id))
  end
end
