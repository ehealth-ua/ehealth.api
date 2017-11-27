defmodule EHealth.Web.LegalEntityView do
  @moduledoc """
  Sample view for LegalEntitys controller.
  """
  use EHealth.Web, :view

  alias EHealth.LegalEntities.LegalEntity

  def render("index.json", %{legal_entities: legal_entities}) do
    render_many(legal_entities, __MODULE__, "legal_entity.json")
  end

  def render("show.json", %{legal_entity: legal_entity}) do
    render_one(legal_entity, __MODULE__, "legal_entity.json")
  end

  def render("legal_entity.json", %{legal_entity: %LegalEntity{} = legal_entity}) do
    %{medical_service_provider: msp} = legal_entity
    %{
      id: legal_entity.id,
      name: legal_entity.name,
      short_name: legal_entity.short_name,
      public_name: legal_entity.public_name,
      status: legal_entity.status,
      type: legal_entity.type,
      owner_property_type: legal_entity.owner_property_type,
      legal_form: legal_entity.legal_form,
      edrpou: legal_entity.edrpou,
      kveds: legal_entity.kveds,
      addresses: legal_entity.addresses,
      phones: legal_entity.phones,
      email: legal_entity.email,
      is_active: legal_entity.is_active,
      inserted_by: legal_entity.inserted_by,
      updated_by: legal_entity.updated_by,
      inserted_at: legal_entity.inserted_at,
      updated_at: legal_entity.updated_at,
      nhs_verified: legal_entity.nhs_verified,
      mis_verified: legal_entity.mis_verified,
      medical_service_provider: render_one(msp, __MODULE__, "medical_service_provider.json")
    }
  end

  def render("legal_entity.json", %{legal_entity: legal_entity}) do
    legal_entity
  end

  def render("medical_service_provider.json", %{legal_entity: msp}) do
    %{
      licenses: msp.licenses,
      accreditation: msp.accreditation,
    }
  end

  def render("legal_entity_short.json", %{"legal_entity" => legal_entity}) do
    %{
      "id" => Map.get(legal_entity, "id"),
      "name" => Map.get(legal_entity, "name"),
      "short_name": Map.get(legal_entity, "short_name"),
      "legal_form": Map.get(legal_entity, "legal_form"),
      "edrpou": Map.get(legal_entity, "edrpou"),
    }
  end
  def render("legal_entity_short.json", %{legal_entity: legal_entity}) do
    %{
      "id" => legal_entity.id,
      "name" => legal_entity.name,
      "short_name": legal_entity.short_name,
      "legal_form": legal_entity.legal_form,
      "edrpou": legal_entity.edrpou
    }
  end
  def render("legal_entity_short.json", _), do: %{}

  def render("show_reimbursement.json", %{legal_entity: legal_entity}) do
    Map.take(legal_entity, ~w(id name short_name public_name type edrpou status)a)
  end
end
