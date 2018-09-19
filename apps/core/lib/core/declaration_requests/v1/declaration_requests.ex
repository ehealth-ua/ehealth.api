defmodule Core.DeclarationRequests do
  @moduledoc false

  import Core.API.Helpers.Connection, only: [get_consumer_id: 1, get_client_id: 1]
  import Ecto.Changeset
  import Ecto.Query
  import Core.DeclarationRequests.Validator

  alias Core.DeclarationRequests.API.Approve
  alias Core.DeclarationRequests.API.Creator
  alias Core.DeclarationRequests.API.Documents
  alias Core.DeclarationRequests.API.ResendOTP
  alias Core.DeclarationRequests.API.Sign
  alias Core.DeclarationRequests.DeclarationRequest
  alias Core.Divisions.Division
  alias Core.Employees.Employee
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.Persons.Validator, as: PersonsValidator
  alias Core.Repo
  alias Core.Validators.Addresses
  alias Core.Validators.JsonSchema
  alias Core.Validators.Reference
  alias Ecto.Multi

  @mithril_api Application.get_env(:core, :api_resolvers)[:mithril]
  @channel_cabinet DeclarationRequest.channel(:cabinet)
  @channel_mis DeclarationRequest.channel(:mis)
  @status_rejected DeclarationRequest.status(:rejected)
  @status_approved DeclarationRequest.status(:approved)

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

  def changeset(%DeclarationRequest{} = declaration_request, params) do
    cast(declaration_request, params, @fields_optional)
  end

  def list(params) do
    DeclarationRequest
    |> order_by([dr], desc: :inserted_at)
    |> filter_by_employee_id(params)
    |> filter_by_legal_entity_id(params)
    |> filter_by_status(params)
    |> Repo.paginate(params)
  end

  def approve(id, verification_code, headers) do
    user_id = get_consumer_id(headers)

    with declaration_request <- get_by_id!(id),
         :ok <- validate_channel(declaration_request, @channel_mis),
         updates <-
           changeset(declaration_request, %{
             status: @status_approved,
             updated_by: user_id
           }),
         :ok <- validate_status_transition(updates) do
      Multi.new()
      |> Multi.run(:verification, fn _ -> Approve.verify(declaration_request, verification_code, headers) end)
      |> Multi.update(:declaration_request, updates)
      |> Repo.transaction()
    end
  end

  def approve(id, headers) do
    user_id = get_consumer_id(headers)

    with declaration_request <- get_by_id!(id),
         :ok <- validate_channel(declaration_request, @channel_cabinet),
         {:ok, %{"data" => user}} <- @mithril_api.get_user_by_id(user_id, headers),
         :ok <- check_user_person_id(user, declaration_request.mpi_id),
         {:ok, person} <- Reference.validate(:person, declaration_request.mpi_id),
         :ok <- validate_tax_id(user["tax_id"], person["tax_id"]),
         updates <-
           changeset(declaration_request, %{
             status: @status_approved,
             updated_by: user_id
           }),
         :ok <- validate_status_transition(updates) do
      Multi.new()
      |> Multi.run(:verification, fn _ -> Approve.verify(declaration_request, headers) end)
      |> Multi.update(:declaration_request, updates)
      |> Repo.transaction()
    end
  end

  def reject(id, user_id) do
    with %DeclarationRequest{} = declaration_request <- get_by_id!(id),
         updates <-
           declaration_request
           |> change
           |> put_change(:status, @status_rejected)
           |> put_change(:updated_by, user_id),
         :ok <- validate_status_transition(updates) do
      Repo.update(updates)
    end
  end

  defdelegate sign(params, headers), to: Sign
  defdelegate resend_otp(id, headers), to: ResendOTP

  def get_documents(declaration_id) do
    DeclarationRequest
    |> where([dr], dr.declaration_id == ^declaration_id)
    |> Repo.one!()
    |> Documents.generate_links()
  end

  def get_by_id!(id), do: get_by_id!(id, %{})
  def get_by_id!(id, nil), do: get_by_id!(id, %{})

  def get_by_id!(id, params) do
    DeclarationRequest
    |> where([dr], dr.id == ^id)
    |> filter_by_legal_entity_id(params)
    |> Repo.one!()
  end

  def create_offline(params, headers) do
    user_id = get_consumer_id(headers)
    client_id = get_client_id(headers)

    with :ok <- JsonSchema.validate(:declaration_request, %{"declaration_request" => params}),
         params <- lowercase_email(params),
         :ok <- PersonsValidator.validate(params["person"]),
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

  def filter_by_legal_entity_id(query, %{"legal_entity_id" => legal_entity_id}) do
    where(query, [r], fragment("?->'legal_entity'->>'id' = ?", r.data, ^legal_entity_id))
  end

  def filter_by_legal_entity_id(query, _), do: query
end
