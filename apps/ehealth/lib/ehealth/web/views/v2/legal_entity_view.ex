defmodule EHealth.Web.V2.LegalEntityView do
  @moduledoc """
  View for LegalEntities controller.
  """

  use EHealth.Web, :view
  alias Core.LegalEntities.LegalEntity

  @fields ~w(
    id
    name
    short_name
    public_name
    status
    owner_property_type
    legal_form
    edrpou
    phones
    email
    is_active
    nhs_verified
    nhs_reviewed
    nhs_comment
    archive
    website
    beneficiary
    receiver_funds_code
    inserted_at
    inserted_by
    updated_at
    updated_by
    kveds
    type
    edr_verified
    residence_address
    accreditation
  )a

  def render("index.json", %{legal_entities: legal_entities}) do
    render_many(legal_entities, __MODULE__, "legal_entity.json")
  end

  def render("show.json", %{legal_entity: legal_entity}) do
    render_one(legal_entity, __MODULE__, "legal_entity.json")
  end

  def render("legal_entity.json", %{legal_entity: %LegalEntity{} = legal_entity}) do
    legal_entity
    |> Map.take(@fields)
    |> Map.put(:license, render_one(legal_entity.license, __MODULE__, "license.json"))
    |> Map.put(:edr, render_one(legal_entity.edr_data, __MODULE__, "edr_data.json"))
  end

  def render("legal_entity.json", %{legal_entity: legal_entity}), do: legal_entity

  def render("license.json", %{legal_entity: license}) do
    Map.take(license, ~w(
      active_from_date
      expiry_date
      id
      inserted_at
      inserted_by
      is_active
      issued_by
      issued_date
      issuer_status
      license_number
      order_no
      type
      updated_at
      updated_by
      what_licensed
    )a)
  end

  def render("edr_data.json", %{legal_entity: edr_data}) do
    Map.take(edr_data, ~w(id name short_name public_name legal_form edrpou kveds registration_address state)a)
  end
end
