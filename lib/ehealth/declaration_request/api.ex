defmodule EHealth.DeclarationRequest.API do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  import EHealth.Paging
  import EHealth.DeclarationRequest.API.Validations

  alias Ecto.Multi
  alias Ecto.UUID
  alias EHealth.Repo
  alias EHealth.API.PRM
  alias EHealth.DeclarationRequest
  alias EHealth.DeclarationRequest.API.Create
  alias EHealth.DeclarationRequest.API.Approve
  alias EHealth.DeclarationRequest.API.Helpers
  alias EHealth.DeclarationRequest.API.Validations

  @required_fields ~w(
    data
    status
    authentication_method_current
    printout_content
    inserted_by
    updated_by
  )a

  @fields ~w(
    data
    status
    documents
    authentication_method_current
    printout_content
    inserted_by
    updated_by
  )a

  def get_declaration_request_by_id!(id) do
    Repo.get!(DeclarationRequest, id)
  end

  def list_declaration_requests(params) do
    query = from dr in DeclarationRequest,
      order_by: [desc: :inserted_at]

    query
    |> filter_by_employee_id(params)
    |> filter_by_legal_entity_id(params)
    |> filter_by_status(params)
    |> Repo.page(get_paging(params, Confex.get(:ehealth, :declaration_requests_per_page)))
  end

  defp filter_by_legal_entity_id(query, %{"legal_entity_id" => legal_entity_id}) do
    where(query, [r], fragment("?->'legal_entity'->>'id' = ?", r.data, ^legal_entity_id))
  end
  defp filter_by_legal_entity_id(query, _), do: query

  defp filter_by_employee_id(query, %{"employee_id" => employee_id}) do
    where(query, [r], fragment("?->'employee'->>'id' = ?", r.data, ^employee_id))
  end
  defp filter_by_employee_id(query, _), do: query

  defp filter_by_status(query, %{"status" => status}) when is_binary(status) do
    where(query, [r], r.status == ^status)
  end
  defp filter_by_status(query, _), do: query

  def create(attrs, user_id, client_id) do
    with {:ok, attrs} <- Validations.validate_schema(attrs),
         {:ok, _} <- Validations.validate_addresses(get_in(attrs, ["person", "addresses"])),
         {:ok, %{"data" => global_parameters}} <- PRM.get_global_parameters(),
         {:ok, %{"data" => employee}} <- PRM.get_employee_by_id(attrs["employee_id"]),
         {:ok, %{"data" => division}} <- PRM.get_division_by_id(attrs["division_id"]),
         {:ok, %{"data" => legal_entity}} <- PRM.get_legal_entity_by_id(client_id) do
      updates = [status: "CANCELLED", updated_at: DateTime.utc_now(), updated_by: user_id]

      auxilary_entities = %{
        employee: employee,
        global_parameters: global_parameters,
        division: division,
        legal_entity: legal_entity
      }

      Multi.new
      |> Multi.update_all(:previous_requests, pending_declaration_requests(attrs, client_id), set: updates)
      |> Multi.insert(:declaration_request, create_changeset(attrs, user_id, auxilary_entities))
      |> Multi.run(:finalize, &finalize/1)
      |> Repo.transaction
    end
  end

  def approve(id, verification_code, user_id) do
    with declaration_request <- Repo.get!(DeclarationRequest, id) do
      updates = update_changeset(declaration_request, %{status: "APPROVED", updated_by: user_id})

      Multi.new
      |> Multi.run(:verification, fn(_) -> Approve.verify(declaration_request, verification_code) end)
      |> Multi.update(:declaration_request, updates)
      |> Repo.transaction
    end
  end

  def finalize(multi) do
    declaration_request = multi.declaration_request
    authorization = declaration_request.authentication_method_current

    case authorization["type"] do
      "OTP" ->
        case Create.send_verification_code(authorization["number"]) do
          {:ok, _} ->
            {:ok, declaration_request}
          {:error, error} ->
            {:error, error}
        end
      "OFFLINE" ->
        case Create.generate_upload_urls(declaration_request.id) do
          {:ok, documents} ->
            declaration_request
            |> update_changeset(%{documents: documents})
            |> Repo.update
          {:error, _} = bad_result ->
            bad_result
        end
    end
  end

  def create_changeset(attrs, user_id, auxilary_entities) do
    %{
      employee: employee,
      global_parameters: global_parameters,
      division: division,
      legal_entity: legal_entity
    } = auxilary_entities

    specialities = employee["doctor"]["specialities"]

    attrs = Map.drop(attrs, ["employee_id", "division_id"])

    %EHealth.DeclarationRequest{}
    |> cast(%{data: attrs}, [:data])
    |> validate_legal_entity_employee(legal_entity, employee)
    |> validate_legal_entity_division(legal_entity, division)
    |> validate_patient_birth_date()
    |> validate_patient_age(Enum.map(specialities, &(&1["speciality"])), global_parameters["adult_age"])
    |> validate_patient_phone_number()
    |> validate_tax_id()
    |> validate_person_addresses()
    |> validate_confidant_persons_tax_id()
    |> put_start_end_dates(global_parameters)
    |> put_in_data(:employee, employee)
    |> put_in_data(:division, division)
    |> put_in_data(:legal_entity, legal_entity)
    |> put_change(:id, UUID.generate())
    |> put_change(:status, "NEW")
    |> put_change(:inserted_by, user_id)
    |> put_change(:updated_by, user_id)
    |> Create.determine_auth_method_for_mpi()
    |> Create.generate_printout_form()
    |> validate_required(@required_fields)
  end

  def put_in_data(changeset, key, value) do
     new_data =
       changeset
       |> get_field(:data)
       |> put_in([key], value)

     put_change(changeset, :data, new_data)
   end

  def update_changeset(%EHealth.DeclarationRequest{} = declaration_request, attrs) do
    declaration_request
    |> cast(attrs, @fields)
  end

  def put_start_end_dates(changeset, global_parameters) do
    %{
      "declaration_request_term" => term,
      "declaration_request_term_unit" => unit,
      "adult_age" => adult_age
    } = global_parameters

    adult_age = String.to_integer(adult_age)
    term = String.to_integer(term)

    normalized_unit =
      unit
      |> String.downcase
      |> String.to_atom

    data = get_field(changeset, :data)
    birth_date = get_in(data, ["person", "birth_date"])

    start_date = Date.utc_today()
    end_date = Helpers.request_end_date(start_date, [{normalized_unit, term}], birth_date, adult_age)

    new_data =
      data
      |> put_in(["end_date"], end_date)
      |> put_in(["start_date"], start_date)

    put_change(changeset, :data, new_data)
  end

  def pending_declaration_requests(raw_declaration_request, legal_entity_id) do
    tax_id          = get_in(raw_declaration_request, ["person", "tax_id"])
    employee_id     = get_in(raw_declaration_request, ["employee_id"])

    from p in EHealth.DeclarationRequest,
      where: p.status in ["NEW", "APPROVED"],
      where: fragment("? #>> ? = ?", p.data, "{person, tax_id}", ^tax_id),
      where: fragment("? #>> ? = ?", p.data, "{employee_id}", ^employee_id),
      where: fragment("? #>> ? = ?", p.data, "{legal_entity_id}", ^legal_entity_id)
  end
end
