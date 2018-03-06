defmodule EHealth.Web.CabinetView do
  @moduledoc false

  use EHealth.Web, :view

  def render("email_verification.json", _) do
    %{}
  end

  def render("show.json", %{person: person}) do
    Map.take(
      person,
      ~w(
        first_name
        last_name
        second_name
        birth_date
        birth_country
        birth_settlement
        gender
        email
        tax_id
        secret
        documents
        addresses
        phones
        authentication_methods
        preferred_way_communication
        emergency_contact
        process_disclosure_data_consent
      )
    )
  end
end
