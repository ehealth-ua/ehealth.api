defmodule Core.LegalEntities.Renderer do
  @moduledoc false

  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.License

  def render("show_reimbursement.json", %LegalEntity{} = legal_entity) do
    Map.take(legal_entity, ~w(id name short_name public_name type edrpou status)a)
  end

  def render("show_reimbursement_details.json", %LegalEntity{} = legal_entity) do
    legal_entity
    |> Map.take(~w(id name short_name public_name type edrpou status)a)
    |> Map.merge(%{
      "accreditation" => render("accreditation.json", legal_entity.accreditation),
      "licenses" => render("licenses.json", legal_entity.license)
    })
  end

  def render("accreditation.json", nil), do: nil

  def render("accreditation.json", accreditation) do
    Map.take(accreditation, ~w(category issued_date expiry_date order_no order_date))
  end

  def render("licenses.json", %License{} = license) do
    [Map.take(license, ~w(license_number issued_by issued_date expiry_date active_from_date what_licensed order_no)a)]
  end
end
