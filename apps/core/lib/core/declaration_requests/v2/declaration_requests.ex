defmodule Core.V2.DeclarationRequests do
  @moduledoc false

  import Core.API.Helpers.Connection, only: [get_consumer_id: 1, get_client_id: 1]
  import Ecto.Changeset

  alias Core.DeclarationRequests.API.Creator
  alias Core.DeclarationRequests.API.ResendOTP
  alias Core.DeclarationRequests.API.Sign
  alias Core.DeclarationRequests.DeclarationRequest
  alias Core.Divisions.Division
  alias Core.Email.Sanitizer
  alias Core.Employees.Employee
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.Persons.V2.Validator, as: PersonsValidatorV2
  alias Core.Validators.Addresses
  alias Core.Validators.JsonSchema
  alias Core.Validators.Reference

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]

  @fields_optional ~w(
    data
    status
    documents
    authentication_method_current
    printout_content
    inserted_by
    updated_by
    mpi_id
  )a

  @person_create_params ~w(
    addresses
    authentication_methods
    birth_country
    birth_date
    birth_settlement
    confidant_person
    documents
    email
    emergency_contact
    first_name
    gender
    last_name
    patient_signed
    phones
    preferred_way_communication
    process_disclosure_data_consent
    second_name
    secret
    tax_id
    unzr
  )

  defdelegate sign(params, headers), to: Sign
  defdelegate resend_otp(id, headers), to: ResendOTP

  def create_offline(params, headers) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)

    with :ok <- JsonSchema.validate(:declaration_request_v2, %{"declaration_request" => params}),
         params <- lowercase_email(params),
         :ok <- PersonsValidatorV2.validate(params["person"]),
         :ok <- Addresses.validate(get_in(params, ["person", "addresses"]), "RESIDENCE", headers),
         {:ok, %Employee{} = employee} <-
           Reference.validate(:employee, params["employee_id"], "$.declaration_request.employee_id"),
         :ok <- Creator.validate_employee_status(employee),
         :ok <- Creator.validate_employee_speciality(employee),
         %LegalEntity{} = legal_entity <- LegalEntities.get_by_id(client_id),
         {:ok, %Division{} = division} <-
           Reference.validate(:division, params["division_id"], "$.declaration_request.division_id") do
      data = Map.put(params, "channel", DeclarationRequest.channel(:mis))
      Creator.create(data, user_id, params["person"], employee, division, legal_entity, headers)
    end
  end

  def create_online(params, headers) do
    user_id = get_consumer_id(headers)
    params = Map.delete(params, "legal_entity_id")

    with :ok <- JsonSchema.validate(:cabinet_declaration_request, params),
         params <- Map.put(params, "scope", "family_doctor"),
         {:ok, %{"data" => user}} <- @mithril_api.get_user_by_id(user_id, headers),
         :ok <- check_user_person_id(user, params["person_id"]),
         {:ok, person} <- Reference.validate(:person, params["person_id"]),
         :ok <- PersonsValidatorV2.validate(person),
         {:ok, %Employee{} = employee} <- Reference.validate(:employee, params["employee_id"]),
         :ok <- Creator.validate_employee_status(employee),
         :ok <- Creator.validate_employee_speciality(employee),
         {:ok, %Division{} = division} <- Reference.validate(:division, params["division_id"]),
         {:ok, %LegalEntity{} = legal_entity} <- Reference.validate(:legal_entity, division.legal_entity_id),
         :ok <- validate_tax_id(user["tax_id"], person["tax_id"]) do
      data =
        params
        |> Map.put("person", Map.take(person, @person_create_params))
        |> Map.put("employee", employee)
        |> Map.put("channel", DeclarationRequest.channel(:cabinet))

      Creator.create(data, user_id, person, employee, division, legal_entity, headers)
    end
  end

  defp validate_tax_id(user_tax_id, person_tax_id) do
    if user_tax_id == person_tax_id do
      :ok
    else
      {:error, {:"422", "Invalid person"}}
    end
  end

  defp check_user_person_id(user, person_id) do
    if user["person_id"] == person_id do
      :ok
    else
      {:error, :forbidden}
    end
  end

  def changeset(%DeclarationRequest{} = declaration_request, params) do
    cast(declaration_request, params, @fields_optional)
  end

  defp lowercase_email(params) do
    path = ~w(person email)
    email = get_in(params, path)
    put_in(params, path, Sanitizer.sanitize(email))
  end
end
