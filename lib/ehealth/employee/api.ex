defmodule EHealth.Employee.API do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  import EHealth.Paging
  import EHealth.Utils.Connection
  import EHealth.Employee.EmployeeUpdater, only: [put_updated_by: 2]
  import EHealth.LegalEntity.API, only: [get_client_type_name: 2]
  import EHealth.Plugs.ClientContext, only: [authorize_legal_entity_id: 3]

  alias EHealth.Repo
  alias EHealth.Employee.Request
  alias EHealth.OAuth.API, as: OAuth
  alias EHealth.Employee.UserCreateRequest
  alias EHealth.Employee.EmployeeCreator
  alias EHealth.Employee.UserRoleCreator
  alias EHealth.Man.Templates.EmployeeRequestInvitation, as: EmployeeRequestInvitationTemplate
  alias EHealth.Bamboo.Emails.EmployeeRequestInvitation, as: EmployeeRequestInvitationEmail
  alias EHealth.Man.Templates.EmployeeCreatedNotification, as: EmployeeCreatedNotificationTemplate
  alias EHealth.Bamboo.Emails.EmployeeCreatedNotification, as: EmployeeCreatedNotificationEmail
  alias EHealth.Validators.RemoteForeignKey
  alias EHealth.API.Mithril
  alias EHealth.API.PRM
  alias EHealth.Employee.Validator
  alias EHealth.PRM.LegalEntities.Schema, as: LegalEntity
  alias EHealth.PRMRepo

  require Logger

  @status_new "NEW"
  @status_approved "APPROVED"
  @status_rejected "REJECTED"

  def get_employee_request_by_id!(id) do
    Repo.get!(Request, id)
  end

  def list_employee_requests(params) do
    query = from er in Request,
      order_by: [desc: :inserted_at]

    {employee_requests, paging} =
      query
      |> filter_by_legal_entity_id(params)
      |> filter_by_status(params)
      |> Repo.page(get_paging(params, Confex.fetch_env!(:ehealth, :employee_requests_per_page)))
    legal_entity_ids =
      employee_requests
      |> Enum.reduce([], fn %{data: data}, acc ->
        id = Map.get(data, "legal_entity_id")
        if id, do: [id | acc], else: acc
      end)
      |> Enum.uniq
    legal_entities =
      LegalEntity
      |> where([le], le.id in ^legal_entity_ids)
      |> PRMRepo.all
      |> Enum.into(%{}, &({Map.get(&1, :id), &1}))

    employee_requests =
      Enum.map(employee_requests, fn request ->
        legal_entity = Map.get(legal_entities, Map.get(request.data, "legal_entity_id"), %{})
        Map.put(request, :legal_entity, legal_entity)
      end)
    {employee_requests, paging}
  end

  defp filter_by_legal_entity_id(query, %{"legal_entity_id" => legal_entity_id}) do
    where(query, [r], fragment("?->>'legal_entity_id' = ?", r.data, ^legal_entity_id))
  end

  defp filter_by_legal_entity_id(query, _) do
    query
  end

  defp filter_by_status(query, %{"status" => status}) when is_binary(status) do
    where(query, [r], r.status == ^status)
  end
  defp filter_by_status(query, _) do
    where(query, [r], r.status == @status_new)
  end

  def create_employee_request(attrs), do: create_employee_request(attrs, nil)
  def create_employee_request(attrs, headers) do
    with :ok <- Validator.validate(attrs) do
      attrs
      |> Map.fetch!("employee_request")
      |> get_or_create_employee_request(headers)
    end
  end

  def create_user_by_employee_request(params, headers) do
    %Request{data: data} =
      params
      |> Map.fetch!("id")
      |> get_employee_request_by_id!()

    user_email =
      data
      |> Map.fetch!("party")
      |> Map.fetch!("email")

    %UserCreateRequest{}
    |> user_employee_request_changeset(params)
    |> OAuth.create_user(user_email, headers)
  end

  def send_email({:ok, %Request{data: data} = employee_request} = result, template, sender) do
    with {:ok, body} <- template.render(employee_request) do
      try do
        data
        |> get_in(["party", "email"])
        |> sender.send(body) # ToDo: use postboy when it is ready
      rescue
        e -> Logger.error(e.message)
      end
      result
    end
  end
  def send_email(error, _template, _sender), do: error

  def reject_employee_request(id) do
    employee_request = get_employee_request_by_id!(id)
    with {:ok, employee_request} <- check_transition_status(employee_request) do
      update_status(employee_request, @status_rejected)
    end
  end

  def approve_employee_request(id, req_headers) do
    employee_request = get_employee_request_by_id!(id)

    with {:ok, employee_request} <- check_transition_status(employee_request),
         {:ok, employee} <- create_or_update_employee(employee_request, req_headers),
         {:ok, employee_request} <- update_status(employee_request, employee, @status_approved)
    do
      send_email({:ok, employee_request}, EmployeeCreatedNotificationTemplate, EmployeeCreatedNotificationEmail)
    end
  end

  def create_or_update_employee(%Request{data: %{"employee_id" => employee_id} = employee_request}, req_headers) do
    with {:ok, %{"data" => employee}} <- PRM.get_employee_by_id(employee_id),
         party_id <- get_in(employee, ["party", "id"]),
         {:ok, party} <- PRM.get_party_by_id(party_id, req_headers),
         {:ok, _} <- EmployeeCreator.create_party_user(party, req_headers),
         {:ok, _} <- PRM.update_party(Map.fetch!(employee_request, "party"), party_id, req_headers)
    do
      employee_request
      |> update_doctor(employee)
      |> Map.put("employee_type", Map.get(employee, "employee_type"))
      |> put_updated_by(req_headers)
      |> PRM.update_employee(employee_id, req_headers)
    end
  end
  def create_or_update_employee(%Request{} = employee_request, req_headers) do
    employee_request
    |> EmployeeCreator.create(req_headers)
    |> UserRoleCreator.create(req_headers)
  end
  def create_or_update_employee(error, _), do: error

  def update_doctor(employee_request, %{"doctor" => doctor}) do
    Map.put(employee_request, "doctor", Map.merge(doctor, Map.get(employee_request, "doctor")))
  end

  def check_transition_status(%Request{status: @status_new} = employee_request) do
    {:ok, employee_request}
  end

  def check_transition_status(%Request{status: status}) do
    {:conflict, "Employee request status is #{status} and cannot be updated"}
  end
  def check_transition_status(err), do: err

  def update_status(%Request{} = employee_request, %{"data" => %{"id" => id}}, status) do
    employee_request
    |> changeset(%{status: status, employee_id: id})
    |> Repo.update()
  end
  def update_status(%Request{} = employee_request, status) do
    employee_request
    |> changeset(%{status: status})
    |> Repo.update()
  end
  def update_status(err, _status), do: err

  defp validate_foreign_keys(changeset, attrs) do
    changeset
    |> RemoteForeignKey.validate(:legal_entity_id, get_in(attrs, [:data, "legal_entity_id"]))
    |> RemoteForeignKey.validate(:division_id, get_in(attrs, [:data, "division_id"]))
    |> RemoteForeignKey.validate(:employee_id, get_in(attrs, [:data, "employee_id"]))
  end

  def changeset(%Request{} = schema, attrs) do
    fields = ~W(
      data
      status
      employee_id
    )a

    required_fields = ~W(data status)a

    schema
    |> cast(attrs, fields)
    |> validate_required(required_fields)
    |> validate_foreign_keys(attrs)
  end

  def user_employee_request_changeset(%UserCreateRequest{} = schema, attrs) do
    fields = ~W(
      password
    )a

    schema
    |> cast(attrs, fields)
    |> validate_required(fields)
  end

  def check_employee_request(headers, id) do
    headers
    |> get_consumer_id()
    |> get_user_email()
    |> match_employee_request(id)
  end

  defp get_user_email(nil), do: nil
  defp get_user_email(consumer_id) do
    consumer_id
    |> Mithril.get_user_by_id()
    |> fetch_user_email()
  end

  defp fetch_user_email({:ok, body}), do: get_in(body, ["data", "email"])
  defp fetch_user_email({:error, _reason}), do: nil

  defp match_employee_request(user_email, id) do
    with %Request{data: data} <- get_employee_request_by_id!(id) do
      email = get_in(data, ["party", "email"])
      case user_email == email do
        true -> :ok
        _ -> {:error, :forbidden}
      end
    end
  end

  def get_employees(params, headers) do
    params
    |> get_employees_search_params()
    |> PRM.get_employees(headers)
    |> filter_employees_response()
  end

  def filter_employees_response({:ok, %{"data" => data} = response}) do
    data = Enum.map(data, fn(employee) ->
      employee
      |> Map.drop(["inserted_by", "updated_by", "is_active"])
      |> filter_doctor_response()
    end)

    {:ok, Map.put(response, "data", data)}
  end
  def filter_employees_response(err), do: err

  def filter_doctor_response(%{"doctor" => doctor} = data) do
    doctor = Map.drop(doctor, ["science_degree", "qualifications", "educations"])
    Map.put(data, "doctor", doctor)
  end
  def filter_doctor_response(data), do: data

  defp get_employees_search_params(params) do
    Map.merge(params, %{
      "is_active" => true,
      "expand" => true,
    })
  end

  def get_employee_by_id(id, headers, expand \\ true) do
    client_id = get_client_id(headers)
    with {:ok, employee}     <- PRM.get_employee_by_id(id, headers),
         {:ok, client_type}  <- get_client_type_name(client_id, headers),
          :ok                <- employee
                                |> get_in(["data", "legal_entity_id"])
                                |> authorize_legal_entity_id(client_id, client_type),
         {:ok, party}        <- get_party(employee, headers),
         {:ok, division}     <- get_division(employee, headers),
         {:ok, legal_entity} <- get_legal_entity(employee, headers)
    do
      {:ok, employee
            |> put_in(~w(data division), division["data"])
            |> put_in(~w(data party), party["data"])
            |> put_in(~w(data legal_entity), legal_entity["data"])
            |> filter_employee_response(expand)
      }
    end
  end

  def get_party(%{"data" => %{"party" => %{"id" => id}}}, headers) when not is_nil(id) do
    PRM.get_party_by_id(id, headers)
  end
  def get_party(_, _), do: {:ok, %{"data" => %{}}}

  def get_division(%{"data" => %{"division_id" => id}}, headers) when not is_nil(id) do
    PRM.get_division_by_id(id, headers)
  end
  def get_division(_, _), do: {:ok, %{"data" => %{}}}

  def get_legal_entity(%{"data" => %{"legal_entity" => %{"id" => id}}}, headers) when not is_nil(id) do
    PRM.get_legal_entity_by_id(id, headers)
  end
  def get_legal_entity(_, _), do: {:ok, %{"data" => %{}}}

  # TODO: fucking crooked nail, use views instead. Asshole
  defp filter_employee_response(employee_response, expand) do
    employee =
      employee_response
      |> Map.get("data")
      |> Map.drop(["updated_by", "inserted_by"])
      |> drop_related_fields(expand)
      |> filter_party_response()
      |> filter_legal_entity_response()

    Map.put(employee_response, "data", employee)
  end

  def drop_related_fields(map, true), do: Map.drop(map, ["party_id", "legal_entity_id", "division_id"])
  def drop_related_fields(map, _), do: map

  def filter_party_response(%{"party" => party} = data) do
    party = Map.drop(party, ["updated_by", "inserted_by"])
    Map.put(data, "party", party)
  end
  def filter_party_response(data), do: data

  def filter_legal_entity_response(%{"legal_entity" => legal_entity} = data) do
    filter = ~w(
      updated_by
      inserted_by
      inserted_at
      updated_at
      phones
      medical_service_provider
      kveds
      is_active
      email
      created_by_mis_client_id
      addresses
    )

    legal_entity = Map.drop(legal_entity, filter)
    Map.put(data, "legal_entity", legal_entity)
  end
  def filter_legal_entity_response(data), do: data

  def get_or_create_employee_request(%{"employee_id" => employee_id} = params, headers) do
    with {:ok, employee} <- PRM.get_employee_by_id(employee_id, headers),
         {:ok, employee} <- check_tax_id(params, employee),
         {:ok, _employee} <- check_employee_type(params, employee),
         :ok <- validate_status_type(employee)
    do
      get_or_create_employee_request(params)
    end
  end
  def get_or_create_employee_request(data, _), do: get_or_create_employee_request(data)
  def get_or_create_employee_request(data) do
    %Request{}
    |> changeset(%{data: Map.delete(data, "status"), status: Map.fetch!(data, "status")})
    |> Repo.insert()
    |> send_email(EmployeeRequestInvitationTemplate, EmployeeRequestInvitationEmail)
  end

  def validate_status_type(%{"data" => %{"employee_type" => "OWNER", "status" => "APPROVED", "is_active" => false}}) do
    {:error, {:conflict, "employee is dismissed"}}
  end
  def validate_status_type(%{"data" => %{"employee_type" => _, "status" => "DISMISSED", "is_active" => true}}) do
    {:error, {:conflict, "employee is dismissed"}}
  end
  def validate_status_type(_), do: :ok

  def check_tax_id(%{"party" => %{"tax_id" => tax_id}}, employee) do
    case tax_id == get_in(employee, ["data", "party", "tax_id"]) do
      true -> {:ok, employee}
      false -> {:error, {:conflict, "tax_id doens't match"}}
    end
  end

  def check_employee_type(%{"employee_type" => employee_type}, employee) do
    case employee_type == get_in(employee, ["data", "employee_type"]) do
      true -> {:ok, employee}
      false -> {:error, {:conflict, "employee_type doens't match"}}
    end
  end
end
