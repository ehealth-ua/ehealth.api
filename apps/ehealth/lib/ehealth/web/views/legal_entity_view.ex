defmodule EHealth.Web.LegalEntityView do
  @moduledoc """
  Sample view for LegalEntitys controller.
  """
  use EHealth.Web, :view
  alias EHealth.LegalEntities.LegalEntity

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
    inserted_by
    updated_by
    inserted_at
    updated_at
    nhs_verified
    mis_verified
    archive
    website
    beneficiary
    receiver_funds_code
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
    %{
      "id" => Map.get(legal_entity, "id"),
      "name" => Map.get(legal_entity, "name"),
      short_name: Map.get(legal_entity, "short_name"),
      legal_form: Map.get(legal_entity, "legal_form"),
      edrpou: Map.get(legal_entity, "edrpou")
    }
  end

  def render("legal_entity_short.json", %{legal_entity: legal_entity}) do
    %{
      "id" => legal_entity.id,
      "name" => legal_entity.name,
      short_name: legal_entity.short_name,
      legal_form: legal_entity.legal_form,
      edrpou: legal_entity.edrpou
    }
  end

  def render("legal_entity_short.json", _), do: %{}

  def render("show_reimbursement.json", %{legal_entity: legal_entity}) do
    Map.take(legal_entity, ~w(id name short_name public_name type edrpou status)a)
  end
end
