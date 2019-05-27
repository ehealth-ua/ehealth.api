defmodule Core.V2.LegalEntities do
  @moduledoc """
  The boundary for the LegalEntity system.
  """

  use Core.Search, Application.get_env(:core, :repos)[:read_prm_repo]

  alias Core.API.MediaStorage
  alias Core.EmployeeRequests
  alias Core.Employees.Employee
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.LegalEntityCreator, as: V1LegalEntityCreator
  alias Core.LegalEntities.License
  alias Core.LegalEntities.V2.LegalEntityCreator
  alias Core.OAuth.API, as: OAuth
  alias Core.PRMRepo
  alias Core.V2.LegalEntities.Validator
  import Ecto.Query

  require Logger

  @pharmacy LegalEntity.type(:pharmacy)
  @outpatient LegalEntity.type(:outpatient)
  @primary_care LegalEntity.type(:primary_care)

  @required_fields ~w(
    name
    status
    type
    edrpou
    addresses
    inserted_by
    updated_by
  )a

  @optional_fields ~w(
    id
    phones
    email
    is_active
    nhs_verified
    nhs_reviewed
    nhs_comment
    created_by_mis_client_id
    archive
    receiver_funds_code
    website
    beneficiary
    edr_verified
    edr_data_id
    accreditation
    license_id
    public_name
    short_name
    residence_address
  )a

  # Create legal entity

  def create(params, headers) do
    with {:ok, request_params, legal_entity_code} <- Validator.decode_and_validate(params, headers),
         license_required <- get_required_license(request_params["type"]),
         %V1LegalEntityCreator{} = state <-
           LegalEntityCreator.get_or_create(
             request_params,
             legal_entity_code,
             license_required,
             headers
           ) do
      with {:ok, %LegalEntity{} = legal_entity} <-
             PRMRepo.transaction(fn ->
               legal_entity_transaction(state, params["signed_legal_entity_request"])
             end),
           {:ok, client_type_id} <- get_client_type_id(Map.fetch!(request_params, "type"), headers),
           {:ok, client, client_connection} <-
             OAuth.upsert_client_with_connection(legal_entity, client_type_id, request_params, headers),
           {:ok, security} <- prepare_security_data(client, client_connection),
           {:ok, employee_request} <- create_employee_request(legal_entity, request_params),
           legal_entity <- legal_entity.id |> LegalEntities.get_by_id_query() |> PRMRepo.one!() do
        {:ok,
         %{
           legal_entity: legal_entity,
           employee_request: employee_request,
           security: security
         }}
      end
    end
  end

  def create(%LegalEntity{} = legal_entity, attrs, author_id) do
    legal_entity
    |> changeset(attrs)
    |> PRMRepo.insert_and_log(author_id)
  end

  defp get_required_license(@primary_care), do: License.type(:msp)
  defp get_required_license(@outpatient), do: License.type(:msp)
  defp get_required_license(@pharmacy), do: License.type(:pharmacy)
  defp get_required_license(_), do: nil

  defp create_employee_request(%LegalEntity{id: id}, request_params) do
    owner = Map.fetch!(request_params, "owner")

    id
    |> prepare_employee_request_data(owner)
    |> put_in(["employee_request", "employee_type"], Employee.type(:owner))
    |> EmployeeRequests.create_owner()
  end

  def store_signed_content(id, input, headers) do
    input
    |> Map.fetch!("signed_legal_entity_request")
    |> MediaStorage.store_signed_content(:legal_entity_bucket, id, "signed_content", headers)
  end

  def changeset(%LegalEntity{} = legal_entity, params) do
    legal_entity
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:edrpou, name: :legal_entities_edrpou_type_status_index)
  end

  defdelegate list(params), to: LegalEntities
  defdelegate get_by_id(id, headers), to: LegalEntities
  defdelegate get_client_type_id(type, headers), to: LegalEntities
  defdelegate prepare_security_data(client, client_connection), to: LegalEntities
  defdelegate prepare_employee_request_data(legal_entity_id, party), to: LegalEntities
  defdelegate legal_entity_transaction(state, params), to: LegalEntities
end
