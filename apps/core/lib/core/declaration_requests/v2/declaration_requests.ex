defmodule Core.V2.DeclarationRequests do
  @moduledoc false

  import Core.API.Helpers.Connection, only: [get_consumer_id: 1, get_client_id: 1]

  alias Core.DeclarationRequests, as: V1DeclarationRequests
  alias Core.DeclarationRequests.API.V2.Creator
  alias Core.DeclarationRequests.DeclarationRequest
  alias Core.Divisions.Division
  alias Core.Employees.Employee
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.Persons.V2.Validator, as: PersonsValidatorV2
  alias Core.Validators.Addresses
  alias Core.Validators.JsonSchema
  alias Core.Validators.Reference

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]

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

  def create_offline(params, headers) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)

    with :ok <- JsonSchema.validate(:declaration_request_v2, %{"declaration_request" => params}),
         params <- lowercase_email(params),
         :ok <- PersonsValidatorV2.validate(params["person"]),
         :ok <- Addresses.validate(get_in(params, ["person", "addresses"]), "RESIDENCE"),
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
         person <- person |> Jason.encode!() |> Jason.decode!(),
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

  defdelegate validate_tax_id(user_tax_id, person_tax_id), to: V1DeclarationRequests

  defdelegate check_user_person_id(user, person_id), to: V1DeclarationRequests

  defdelegate lowercase_email(params), to: V1DeclarationRequests
end
