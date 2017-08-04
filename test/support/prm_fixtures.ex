defmodule EHealth.Test.Support.PRMFixtures do
  @moduledoc false

  alias Ecto.UUID
  alias Ecto.Changeset

  alias EHealth.PRMRepo
  alias EHealth.PRM.GlobalParameters.Schema, as: GlobalParameter
  alias EHealth.PRM.LegalEntities.Schema, as: LegalEntity
  alias EHealth.PRM.MedicalServiceProviders.Schema, as: MedicalServiceProvider

  def global_parameter_attrs(custom_attrs \\ %{}) do
    Map.merge(%{
      parameter: Base.url_encode64(:crypto.strong_rand_bytes(10)),
      value: :rand.normal(),
      inserted_by: UUID.generate(),
      updated_by: UUID.generate()
    }, custom_attrs)
  end

  def legal_entity_attrs(custom_attrs \\ %{}) do
    Map.merge(%{
      id: UUID.generate(),
      is_active: true,
      addresses: [],
      edrpou: "3378113538",
      email: "some email",
      kveds: [],
      legal_form: "240",
      name: "some name",
      owner_property_type: "STATE",
      phones: [],
      public_name: "some public_name",
      short_name: "some short_name",
      status: "ACTIVE",
      mis_verified: "VERIFIED",
      type: "MSP",
      nhs_verified: false,
      updated_by: UUID.generate(),
      inserted_by: UUID.generate(),
      created_by_mis_client_id: UUID.generate()
    }, custom_attrs)
  end

  def medical_service_provider_attrs(custom_attrs \\ %{}) do
    Map.merge(%{
      legal_entity_id: UUID.generate(),
      licenses: [],
      accreditation: %{
        category: "some",
        order_date: "some",
        expiry_date: "some",
        issued_date: "some",
        order_no: "some"
      }
    }, custom_attrs)
  end

  def insert_global_parameter(custom_attrs \\ %{}) do
    attributes = global_parameter_attrs(custom_attrs)

    %GlobalParameter{}
    |> Changeset.change(attributes)
    |> PRMRepo.insert!
  end

  def insert_legal_entity(custom_attrs \\ %{}) do
    attributes = legal_entity_attrs(custom_attrs)

    %LegalEntity{}
    |> Changeset.change(attributes)
    |> PRMRepo.insert!
  end

  def insert_medical_service_provider(custom_attrs \\ %{}) do
    attributes = medical_service_provider_attrs(custom_attrs)

    %MedicalServiceProvider{}
    |> Changeset.change(attributes)
    |> PRMRepo.insert!
  end
end
