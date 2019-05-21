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
  alias Core.ValidationError
  alias Core.Validators.Error
  alias Ecto.Changeset
  import Ecto.Query
  import Core.API.Helpers.Connection, only: [get_consumer_id: 1]

  require Logger

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  @pharmacy LegalEntity.type(:pharmacy)
  @outpatient LegalEntity.type(:outpatient)
  @primary_care LegalEntity.type(:primary_care)

  @required_fields ~w(
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
  )a

  # Create legal entity

  def create(params, headers) do
    consumer_id = get_consumer_id(headers)

    with {:ok, request_params, legal_entity_code} <- Validator.decode_and_validate(params, headers),
         license_required <- get_required_license(request_params["type"]),
         %V1LegalEntityCreator{} = state <-
           LegalEntityCreator.get_or_create(
             request_params,
             legal_entity_code,
             headers
           ),
         %V1LegalEntityCreator{} = state <-
           check_license(
             state,
             request_params["license"],
             license_required,
             state.legal_entity.edr_data_id,
             consumer_id
           ) do
      with {:ok, %LegalEntity{} = legal_entity} <-
             PRMRepo.transaction(fn ->
               legal_entity_transaction(state, params["signed_legal_entity_request"], headers)
             end),
           {:ok, client_type_id} <- get_client_type_id(Map.fetch!(request_params, "type"), headers),
           {:ok, client, client_connection} <-
             OAuth.upsert_client_with_connection(legal_entity, client_type_id, request_params, headers),
           {:ok, security} <- prepare_security_data(client, client_connection),
           {:ok, employee_request} <- create_employee_request(legal_entity, request_params) do
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

  defp check_license(state, nil, nil, _, _), do: state
  defp check_license(_, nil, _, _, _), do: {:error, {:conflict, "License is needed for chosen legal entity type"}}

  defp check_license(_, license, nil, _, _) when license != %{} do
    {:error, {:conflict, "License is not needed for chosen legal entity type"}}
  end

  defp check_license(state, license, required_license, edr_data_id, consumer_id) do
    case Map.pop(license, "id") do
      # insert, validate license
      {nil, license_data} ->
        license_data =
          Map.merge(license_data, %{
            "is_active" => true,
            "inserted_by" => consumer_id,
            "updated_by" => consumer_id
          })

        with %Changeset{valid?: true} = changeset <- License.changeset(%License{}, license_data),
             {_, true} <- {:required_license, get_change(changeset, :type) == required_license},
             expiry_date <- get_change(changeset, :expiry_date),
             {_, true} <-
               {:expiry_date, expiry_date && Date.compare(expiry_date, Date.utc_today()) != :lt} do
          %{state | inserts: state.inserts ++ [fn -> PRMRepo.insert_and_log(changeset, consumer_id) end]}
        else
          {:required_license, _} ->
            {:error, {:conflict, "Legal entity type and license type mismatch"}}

          {:expiry_date, _} ->
            {:error, {:conflict, "License is expired"}}

          error ->
            error
        end

      # validate license
      {id, license_data} when license_data == %{} ->
        with {:ok, license} <- get_license(id),
             {_, true} <- {:required_license, license.type == required_license},
             {_, true} <- {:edr_data, edr_data_id in license.edr_data},
             {_, true} <-
               {:expiry_date, license.expiry_date && Date.compare(license.expiry_date, Date.utc_today()) != :lt} do
          state
        else
          nil ->
            Error.dump(%ValidationError{
              description: "License not found",
              path: "$.license.id"
            })

          {:required_license, _} ->
            {:error, {:conflict, "Legal entity type and license type mismatch"}}

          {:edr_data, _} ->
            {:error, {:conflict, "License doesn't correspond to your legal entity"}}

          {:expiry_date, _} ->
            {:error, {:conflict, "License is expired"}}
        end

      # update, validate license
      {id, license_data} ->
        license_data =
          Map.merge(license_data, %{
            "inserted_by" => consumer_id,
            "updated_by" => consumer_id
          })

        with {:ok, license} <- get_license(id),
             %Changeset{valid?: true} = changeset <- License.changeset(license, license_data),
             {_, false} <- {:license_type, Map.has_key?(changeset.changes, :type)},
             {_, true} <- {:required_license, license.type == required_license},
             {_, true} <- {:edr_data, edr_data_id in license.edr_data},
             changes <- Changeset.apply_changes(changeset),
             {_, true} <-
               {:expiry_date, changes.expiry_date && Date.compare(changes.expiry_date, Date.utc_today()) != :lt} do
          %{state | inserts: state.inserts ++ [fn -> PRMRepo.update_and_log(changeset, consumer_id) end]}
        else
          nil ->
            Error.dump(%ValidationError{
              description: "License not found",
              path: "$.license.id"
            })

          {:license_type, _} ->
            Error.dump(%ValidationError{
              description: "License type can not be updated",
              path: "$.license.type"
            })

          {:required_license, _} ->
            {:error, {:conflict, "Legal entity type and license type mismatch"}}

          {:edr_data, _} ->
            {:error, {:conflict, "License doesn't correspond to your legal entity"}}

          {:expiry_date, _} ->
            {:error, {:conflict, "License is expired"}}

          error ->
            error
        end
    end
  end

  defp get_license(license_id) do
    License
    |> where([l], l.id == ^license_id)
    |> preload(:edr_data)
    |> @read_prm_repo.all()
  end

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
  defdelegate get_client_type_id(type, headers), to: LegalEntities
  defdelegate prepare_security_data(client, client_connection), to: LegalEntities
  defdelegate prepare_employee_request_data(legal_entity_id, party), to: LegalEntities
  defdelegate legal_entity_transaction(state, params, headers), to: LegalEntities
end
