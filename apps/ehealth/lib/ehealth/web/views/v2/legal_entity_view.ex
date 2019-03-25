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
    addresses
    phones
    email
    is_active
    nhs_verified
    nhs_reviewed
    nhs_comment
    mis_verified
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
  )a

  def render("show.json", %{legal_entity: legal_entity}) do
    render_one(legal_entity, __MODULE__, "legal_entity.json")
  end

  def render("legal_entity.json", %{legal_entity: %LegalEntity{} = legal_entity}) do
    %{medical_service_provider: msp} = legal_entity

    legal_entity
    |> Map.take(@fields)
    |> Map.put(:medical_service_provider, render_one(msp, __MODULE__, "medical_service_provider.json"))
  end

  def render("legal_entity.json", %{legal_entity: legal_entity}), do: legal_entity

  def render("medical_service_provider.json", %{legal_entity: msp}),
    do: Map.take(msp, ~w(licenses accreditation)a)
end
