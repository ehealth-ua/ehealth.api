defmodule EHealth.Web.LegalEntityView do
  @moduledoc """
  View for LegalEntities controller.
  """

  use EHealth.Web, :view

  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.RelatedLegalEntity
  alias Core.LegalEntities.Renderer, as: LegalEntitiesRenderer

  @fields ~w(
    id
    name
    short_name
    public_name
    status
    type
    owner_property_type
    legal_form
    edrpou
    kveds
    addresses
    phones
    email
    is_active
    nhs_verified
    nhs_reviewed
    mis_verified
    archive
    website
    beneficiary
    receiver_funds_code
    inserted_at
    inserted_by
    updated_at
    updated_by
  )a

  def render("index.json", %{legal_entities: legal_entities}) do
    render_many(legal_entities, __MODULE__, "legal_entity.json")
  end

  def render("show.json", %{legal_entity: legal_entity}) do
    render_one(legal_entity, __MODULE__, "legal_entity.json")
  end

  def render("legal_entity.json", %{legal_entity: %LegalEntity{} = legal_entity}) do
    %{medical_service_provider: msp} = legal_entity

    legal_entity
    |> Map.take(@fields)
    |> Map.put(:medical_service_provider, render_one(msp, __MODULE__, "medical_service_provider.json"))
  end

  def render("legal_entity.json", %{legal_entity: %RelatedLegalEntity{} = legal_entity}) do
    %{merged_from: merged_from_legal_entity} = legal_entity

    legal_entity
    |> Map.take(~w(reason is_active inserted_at inserted_by)a)
    |> Map.put(:merged_from_legal_entity, render_one(merged_from_legal_entity, __MODULE__, "legator.json"))
  end

  def render("legator.json", %{legal_entity: %LegalEntity{} = legal_entity}) do
    Map.take(legal_entity, ~w(id name edrpou)a)
  end

  def render("legal_entity.json", %{legal_entity: legal_entity}) do
    legal_entity
  end

  def render("medical_service_provider.json", %{legal_entity: msp}) do
    %{
      licenses: msp.licenses,
      accreditation: msp.accreditation
    }
  end

  def render("legal_entity_short.json", %{"legal_entity" => legal_entity}) do
    Map.take(legal_entity, ~w(id name short_name legal_form edrpou))
  end

  def render("legal_entity_short.json", %{legal_entity: legal_entity}) do
    Map.take(legal_entity, ~w(id name short_name legal_form edrpou)a)
  end

  def render("legal_entity_short.json", _), do: %{}

  def render("show_reimbursement.json", %{legal_entity: legal_entity}) do
    LegalEntitiesRenderer.render("show_reimbursement.json", legal_entity)
  end
end
