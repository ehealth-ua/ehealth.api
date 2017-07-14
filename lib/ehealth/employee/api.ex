defmodule EHealth.Employee.API do
  @moduledoc false

  import Ecto.{Query, Changeset}, warn: false
  import EHealth.Paging
  import EHealth.Utils.Pipeline
  import EHealth.Utils.Connection
  import EHealth.Employee.EmployeeUpdater, only: [put_updated_by: 2]

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

  require Logger

  @status_new "NEW"
  @status_approved "APPROVED"
  @status_rejected "REJECTED"

  def get_employee_request_by_id!(id) do
    Repo.get!(Request, id)
  end

  def list_employee_requests(params, client_id) do
    query = from er in Request,
      order_by: [desc: :inserted_at]

    query
    |> filter_by_legal_entity_id(client_id)
    |> filter_by_status(params)
    |> Repo.page(get_paging(params, Confex.get(:ehealth, :employee_requests_per_page)))
  end

  defp filter_by_legal_entity_id(query, client_id) do
    where(query, [r], fragment("?->>'legal_entity_id' = ?", r.data, ^client_id))
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
    id
    |> get_employee_request_by_id!()
    |> check_transition_status()
    |> update_status(@status_rejected)
  end

  def approve_employee_request(id, req_headers) do
    employee_request = get_employee_request_by_id!(id)

    employee_request
    |> check_transition_status()
    |> create_or_update_employee(req_headers)
    |> update_status(employee_request, @status_approved)
    |> send_email(EmployeeCreatedNotificationTemplate, EmployeeCreatedNotificationEmail)
  end

  def create_or_update_employee(%Request{data: %{"employee_id" => employee_id}} = employee_request, req_headers) do
    with {:ok, %{"data" => employee}} <- PRM.get_employee_by_id(employee_id),
         {:ok, party} <- PRM.get_party_by_id(get_in(employee, ["party", "id"]), req_headers),
         {:ok, _} <- EmployeeCreator.create_party_user(party, req_headers)
    do
      employee_request
      |> update_doctor(employee)
      |> drop_permanent_keys(employee)
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

  def update_doctor(%{data: data} = employee_request, %{"doctor" => doctor}) do
    employee_request
    |> Map.put(:data, Map.put(data, "doctor", Map.merge(doctor, data["doctor"])))
  end

  defp drop_permanent_keys(%{data: data} = employee_request, %{"employee_type" => employee_type}) do
    employee_request
    |> Map.put(:status, EmployeeCreator.employee_default_status())
    |> Map.put(:data, Map.put(data, "employee_type", employee_type))
  end

  def check_transition_status(%Request{status: @status_new} = employee_request) do
    employee_request
  end

  def check_transition_status(%Request{status: status}) do
    {:conflict, "Employee request status is #{status} and cannot be updated"}
  end
  def check_transition_status(err), do: err

  def update_status({:ok, _}, %Request{} = employee_request, status) do
    update_status(employee_request, status)
  end
  def update_status(err, _employee_request, _status), do: err

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
    )a

    schema
    |> cast(attrs, fields)
    |> validate_required(fields)
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
    pipe_data = %{
      employee_id: id,
      client_id: get_client_id(headers),
      headers: headers,
      expand: expand,
    }
    with {:ok, pipe_data} <- get_employee(pipe_data),
         {:ok, pipe_data} <- check_employee_legal_entity_id(pipe_data),
         {:ok, pipe_data} <- get_employee_relation(pipe_data, "party"),
         {:ok, pipe_data} <- get_employee_relation(pipe_data, "division"),
         {:ok, pipe_data} <- get_employee_relation(pipe_data, "legal_entity"),
         {:ok, pipe_data} <- filter_employee_response(pipe_data) do
         end_pipe({:ok, pipe_data})
    end
  end

  def get_employee(pipe_data) do
    pipe_data
    |> Map.fetch!(:employee_id)
    |> PRM.get_employee_by_id(Map.fetch!(pipe_data, :headers))
    |> put_success_api_response_in_pipe(:employee, pipe_data)
  end

  defp check_employee_legal_entity_id(pipe_data) do
    client_id = Map.fetch!(pipe_data, :client_id)
    legal_entity_id = get_in(pipe_data, [:employee, "data", "legal_entity_id"])

    case client_id == legal_entity_id do
      true -> {:ok, pipe_data}
      _ -> {:error, :forbidden}
    end
  end

  defp get_employee_relation(%{expand: true} = pipe_data, relation_key) do
    pipe_data
    |> get_in([:employee, "data", relation_key <> "_id"])
    |> load_relation_from_prm(relation_key, Map.fetch!(pipe_data, :headers))
    |> put_success_api_response_in_employee(relation_key, pipe_data)
  end
  defp get_employee_relation(pipe_data, _relation_key), do: {:ok, pipe_data}

  defp load_relation_from_prm(nil, _key, _headers), do: {:ok, %{"data" => %{}}}
  defp load_relation_from_prm(id, "party", headers), do: PRM.get_party_by_id(id, headers)
  defp load_relation_from_prm(id, "division", headers), do: PRM.get_division_by_id(id, headers)
  defp load_relation_from_prm(id, "legal_entity", headers), do: PRM.get_legal_entity_by_id(id, headers)

  defp put_success_api_response_in_employee({:ok, %{"data" => resp}}, key, %{employee: employee} = pipe_data) do
    {:ok, Map.put(pipe_data, :employee, put_in(employee, ["data", key], resp))}
  end
  defp put_success_api_response_in_employee(err, _key, _pipe_data), do: err

  # TODO: fucking crooked nail, use views instead. Asshole
  defp filter_employee_response(%{employee: employee_response, expand: expand} = pipe_data) do
    employee =
      employee_response
      |> Map.get("data")
      |> Map.drop(["updated_by", "inserted_by"])
      |> drop_related_fields(expand)
      |> filter_party_response()
      |> filter_legal_entity_response()

    employee_response
    |> Map.put("data", employee)
    |> put_in_pipe(:employee, pipe_data)
  end

  def drop_related_fields(map, true), do: Map.drop(map, ["party_id", "legal_entity_id", "division_id"])
  def drop_related_fields(map, _), do: map

  def filter_party_response(%{"party" => party} = data) do
    party = Map.drop(party, ["updated_by", "inserted_by"])
    Map.put(data, "party", party)
  end
  def filter_party_response(data), do: data

  def filter_legal_entity_response(%{"legal_entity" => legal_entity} = data) do
    filter = ["updated_by", "inserted_by", "inserted_at", "updated_at", "phones", "medical_service_provider",
              "kveds", "is_active",  "email", "created_by_mis_client_id", "addresses"]

    legal_entity = Map.drop(legal_entity, filter)
    Map.put(data, "legal_entity", legal_entity)
  end
  def filter_legal_entity_response(data), do: data

  def get_or_create_employee_request(%{"employee_id" => employee_id} = params, headers) do
    with {:ok, employee} <- PRM.get_employee_by_id(employee_id, headers),
         {:ok, employee} <- check_tax_id(params, employee),
         {:ok, _employee} <- check_employee_type(params, employee) do
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
