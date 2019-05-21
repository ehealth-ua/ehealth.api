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
    edr_verified
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

  def render("deactivation.json", data) do
    render_one(data, __MODULE__, "legal_entity.json")
  end

  def render("legal_entity.json", %{legal_entity: %LegalEntity{} = legal_entity}) do
    %{license: license} = legal_entity

    legal_entity
    |> Map.take(@fields)
    |> Map.put(:addresses, render("address.json", legal_entity))
    |> Map.put(
      :medical_service_provider,
      render_one(
        %{license: license, accreditation: legal_entity.accreditation},
        __MODULE__,
        "medical_service_provider.json"
      )
    )
  end

  def render("address.json", %LegalEntity{} = legal_entity) do
    Enum.reduce(~w(registration_address residence_address)a, [], fn key, acc ->
      value = Map.get(legal_entity, key)

      if value do
        [value | acc]
      else
        acc
      end
    end)
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

  def render("medical_service_provider.json", %{legal_entity: %{license: license, accreditation: accreditation}}) do
    %{
      licenses: [render_one(license, __MODULE__, "license.json")],
      accreditation: accreditation
    }
  end

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
