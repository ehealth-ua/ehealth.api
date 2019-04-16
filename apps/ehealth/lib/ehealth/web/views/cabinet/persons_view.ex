defmodule EHealth.Web.Cabinet.PersonsView do
  @moduledoc false

  use EHealth.Web, :view

  def render("raw.json", %{json: json}) do
    json
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
        unzr
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

  def render("personal_info.json", %{person: person}) do
    Map.take(person, ~w(
      id
      first_name
      last_name
      second_name
    )a)
  end

  def render("person_details.json", %{person: person}) do
    Map.take(person, ~w(
      id
      last_name
      first_name
      second_name
      birth_date
      birth_country
      birth_settlement
      gender
      email
      tax_id
      unzr
      documents
      addresses
      phones
      secret
      emergency_contact
      process_disclosure_data_consent
      authentication_methods
      preferred_way_communication
    )a)
  end
end
