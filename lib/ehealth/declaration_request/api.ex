defmodule EHealth.DeclarationRequest.API do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  import EHealth.DeclarationRequest.API.Validations

  alias Ecto.Multi
  alias Ecto.UUID
  alias EHealth.Repo
  alias EHealth.GlobalParameters
  alias EHealth.LegalEntities
  alias EHealth.Divisions
  alias EHealth.Employees
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.Employees.Employee
  alias EHealth.Divisions.Division
  alias EHealth.DeclarationRequest
  alias EHealth.DeclarationRequest.API.Create
  alias EHealth.DeclarationRequest.API.Approve
  alias EHealth.DeclarationRequest.API.Helpers, as: DeclarationHelpers
  alias EHealth.DeclarationRequest.API.Validations
  alias EHealth.DeclarationRequest.API.Sign
  alias EHealth.DeclarationRequest.API.ResendOTP
  alias EHealth.DeclarationRequest.API.Documents
  alias EHealth.Utils.Phone
  alias EHealth.Utils.Helpers

  require Logger

  @fields ~w(
    data
    status
    documents
    authentication_method_current
    printout_content
    inserted_by
    updated_by
  )a

  @status_new DeclarationRequest.status(:new)
  @status_rejected DeclarationRequest.status(:rejected)
  @status_approved DeclarationRequest.status(:approved)

  @auth_na DeclarationRequest.authentication_method(:na)
  @auth_otp DeclarationRequest.authentication_method(:otp)
  @auth_offline DeclarationRequest.authentication_method(:offline)

  def get_declaration_request_by_declaration_id!(declaration_id) do
    query = from dr in DeclarationRequest,
      where: dr.declaration_id == ^declaration_id

    Repo.one!(query)
  end

  def get_declaration_request_by_id!(id), do: get_declaration_request_by_id!(id, %{})
  def get_declaration_request_by_id!(id, nil), do: get_declaration_request_by_id!(id, %{})
  def get_declaration_request_by_id!(id, params) do
    query = from dr in DeclarationRequest,
      where: dr.id == ^id

    query
    |> filter_by_legal_entity_id(params)
    |> Repo.one!
  end

  def list_declaration_requests(params) do
    query = from dr in DeclarationRequest,
      order_by: [desc: :inserted_at]

    query
    |> filter_by_employee_id(params)
    |> filter_by_legal_entity_id(params)
    |> filter_by_status(params)
    |> Repo.paginate(params)
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
    # TODO: double check user_id/client_id has access to create given employee/legal_entity
    with :ok <- Validations.validate_schema(attrs),
         :ok <- Validations.validate_person(Map.get(attrs, "person")),
         {:ok, _} <- Validations.validate_addresses(get_in(attrs, ["person", "addresses"])),
         {:ok, %Employee{} = employee} <- Helpers.get_assoc_by_func("employee_id",
                                            fn -> Employees.get_by_id(attrs["employee_id"]) end),
         %LegalEntity{} = legal_entity <- LegalEntities.get_by_id(client_id),
         {:ok, %Division{} = division} <- Helpers.get_assoc_by_func("division_id",
                                            fn -> Divisions.get_by_id(attrs["division_id"]) end)
    do
      updates = [
        status: DeclarationRequest.status(:cancelled),
        updated_at: DateTime.utc_now(),
        updated_by: user_id
      ]
      global_parameters = GlobalParameters.get_values()

      auxilary_entities = %{
        employee: employee,
        global_parameters: global_parameters,
        division: division,
        legal_entity: legal_entity
      }

      tax_id = get_in(attrs, ["person", "tax_id"])

      pending_declaration_requests = pending_declaration_requests(tax_id, employee.id, legal_entity.id)

      Multi.new
      |> Multi.update_all(:previous_requests, pending_declaration_requests, set: updates)
      |> Multi.insert(:declaration_request, create_changeset(attrs, user_id, auxilary_entities))
      |> Multi.run(:finalize, &finalize/1)
      |> Multi.run(:urgent_data, &prepare_urgent_data/1)
      |> Repo.transaction
    else
      {:assoc_error, field} ->
         {:error, [{%{description: "#{Helpers.from_filed_to_name(field)} not found", params: [],
                          rule: :required}, "$.declaration_request.#{field}"}]}
      err -> err
    end
  end

  def reject(id, user_id) do
    with %DeclarationRequest{} = declaration_request <- Repo.get(DeclarationRequest, id),
         updates <- declaration_request
                    |> change
                    |> put_change(:status, @status_rejected)
                    |> put_change(:updated_by, user_id),
         :ok <- validate_status_transition(updates)
    do
      Repo.update(updates)
    end
  end

  def validate_status_transition(changeset) do
    from = changeset.data.status
    {_, to} = fetch_field(changeset, :status)

    valid_transitions = [
      {@status_new, @status_rejected},
      {@status_approved, @status_rejected},
      {@status_new, @status_approved},
    ]

    if {from, to} in valid_transitions do
      :ok
    else
      {:error, {:conflict, "Invalid transition"}}
    end
  end

  def approve(id, verification_code, user_id) do
    with declaration_request <- Repo.get!(DeclarationRequest, id),
         updates <- update_changeset(declaration_request, %{
           status: @status_approved,
           updated_by: user_id
         }),
         :ok <- validate_status_transition(updates)
    do
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
      @auth_na ->
        {:ok, declaration_request}

      @auth_otp ->
        case Create.send_verification_code(authorization["number"]) do
          {:ok, _} ->
            {:ok, declaration_request}
          {:error, error} ->
            {:error, error}
        end

      @auth_offline ->
        case Documents.generate_links(declaration_request, ["PUT"]) do
          {:ok, documents} ->
            declaration_request
            |> update_changeset(%{documents: documents})
            |> Repo.update()
          {:error, _} = bad_result ->
            bad_result
        end
    end
  end

  def prepare_urgent_data(multi) do
    declaration_request = multi.finalize()

    filtered_authentication_method_current =
      filter_authentication_method(declaration_request.authentication_method_current)

    filter_document_links = fn documents ->
      filter_fun = fn document -> document["verb"] == "PUT" end
      map_fun = fn document -> Map.drop(document, ["verb"]) end

      documents
      |> Enum.filter(filter_fun)
      |> Enum.map(map_fun)
    end

    urgent_data =
      if declaration_request.documents do
        %{
          authentication_method_current: filtered_authentication_method_current,
          documents: filter_document_links.(declaration_request.documents)
        }
      else
        %{
          authentication_method_current: filtered_authentication_method_current
        }
      end

    {:ok, urgent_data}
  end

  defp filter_authentication_method(%{"number" => number} = method) do
    Map.put(method, "number", Phone.hide_number(number))
  end

  defp filter_authentication_method(method) do
    method
  end

  def update_status(id, status) do
    id
    |> get_declaration_request_by_id!()
    |> update_changeset(%{status: status})
    |> Repo.update()
  end

  def create_changeset(attrs, user_id, auxilary_entities) do
    %{
      employee: employee,
      global_parameters: global_parameters,
      division: division,
      legal_entity: legal_entity
    } = auxilary_entities

    specialities = Map.get(employee.additional_info, "specialities") || []

    attrs = Map.drop(attrs, ["employee_id", "division_id"])

    id = UUID.generate()
    declaration_id = UUID.generate()

    %EHealth.DeclarationRequest{id: id}
    |> cast(%{data: attrs}, [:data])
    |> validate_legal_entity_employee(legal_entity, employee)
    |> validate_legal_entity_division(legal_entity, division)
    |> validate_employee_type(employee)
    |> validate_patient_birth_date()
    |> validate_patient_age(Enum.map(specialities, &(&1["speciality"])), global_parameters["adult_age"])
    |> validate_authentication_method_phone_number()
    |> validate_tax_id()
    |> validate_person_addresses()
    |> validate_confidant_persons_tax_id()
    |> validate_confidant_person_rel_type()
    |> validate_authentication_methods()
    |> validate_scope()
    |> put_start_end_dates(global_parameters)
    |> put_in_data("employee", Create.prepare_employee_struct(employee))
    |> put_in_data("division", Create.prepare_division_struct(division))
    |> put_in_data("legal_entity", Create.prepare_legal_entity_struct(legal_entity))
    |> put_in_data("declaration_id", declaration_id)
    |> put_change(:id, id)
    |> put_change(:declaration_id, declaration_id)
    |> put_change(:status, @status_new)
    |> put_change(:inserted_by, user_id)
    |> put_change(:updated_by, user_id)
    |> Create.put_party_email()
    |> Create.determine_auth_method_for_mpi()
    |> Create.generate_printout_form()
  end

  def put_in_data(changeset, key, value) do
     new_data =
       changeset
       |> get_field(:data)
       |> put_in([key], value)

     put_change(changeset, :data, new_data)
   end

  def update_changeset(%EHealth.DeclarationRequest{} = declaration_request, attrs) do
    cast(declaration_request, attrs, @fields)
  end

  def put_start_end_dates(changeset, global_parameters) do
    %{
      "declaration_term" => term,
      "declaration_term_unit" => unit,
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
    end_date = DeclarationHelpers.request_end_date(start_date, [{normalized_unit, term}], birth_date, adult_age)

    new_data =
      data
      |> put_in(["end_date"], end_date)
      |> put_in(["start_date"], start_date)

    put_change(changeset, :data, new_data)
  end

  def pending_declaration_requests(nil, employee_id, legal_entity_id) do
    from p in EHealth.DeclarationRequest,
      where: p.status in [@status_new, @status_approved],
      where: fragment("? #>> ? = ?", p.data, "{employee, id}", ^employee_id),
      where: fragment("? #>> ? = ?", p.data, "{legal_entity, id}", ^legal_entity_id)
  end

  def pending_declaration_requests(tax_id, employee_id, legal_entity_id) do
    from p in EHealth.DeclarationRequest,
      where: p.status in [@status_new, @status_approved],
      where: fragment("? #>> ? = ?", p.data, "{person, tax_id}", ^tax_id),
      where: fragment("? #>> ? = ?", p.data, "{employee, id}", ^employee_id),
      where: fragment("? #>> ? = ?", p.data, "{legal_entity, id}", ^legal_entity_id)
  end

  def sign(params, headers) do
    params
    |> Validations.decode_and_validate_sign_request(headers)
    |> Sign.check_status(params)
    |> Sign.check_patient_signed()
    |> Sign.compare_with_db()
    |> Sign.check_employee_id(headers)
    |> Sign.check_drfo()
    |> Sign.store_signed_content(params, headers)
    |> Sign.create_or_update_person(headers)
    |> Sign.create_declaration_with_termination_logic(headers)
    |> Sign.update_declaration_request_status(params)
  end

  def resend_otp(params, headers) do
    params
    |> Map.fetch!("id")
    |> get_declaration_request_by_id!()
    |> ResendOTP.check_status()
    |> ResendOTP.check_auth_method()
    |> ResendOTP.init_otp(headers)
  end

  def documents(declaration_id) do
    declaration_id
    |> get_declaration_request_by_declaration_id!()
    |> Documents.generate_links(["GET"])
  end

  def terminate_declaration_requests do
    parameters = GlobalParameters.get_values()

    is_valid? =
      Enum.all?(~w(declaration_request_expiration declaration_request_term_unit), fn param ->
        Map.has_key? parameters, param
      end)

    if is_valid? do
      %{
        "declaration_request_expiration" => term,
        "declaration_request_term_unit" => unit,
      } = parameters

      normalized_unit =
        unit
        |> String.downcase
        |> String.replace_trailing("s", "")

      query = where(DeclarationRequest, [dr],
        datetime_add(dr.inserted_at, ^term, ^normalized_unit) < ^NaiveDateTime.utc_now()
      )

      Multi.new()
      |> Multi.delete_all(:declaration_requests, query)
      |> Repo.transaction()
    end
  end
end
