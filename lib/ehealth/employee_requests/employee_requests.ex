defmodule EHealth.EmployeeRequests do
  @moduledoc false

  import Ecto.Query
  import Ecto.Changeset
  import EHealth.Utils.Connection

  alias EHealth.EmployeeRequests.EmployeeRequest, as: Request
  alias EHealth.Repo
  alias EHealth.PRMRepo
  alias EHealth.Employees.Employee
  alias EHealth.Divisions.Division
  alias EHealth.LegalEntities
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.EmployeeRequests.Validator
  alias EHealth.OAuth.API, as: OAuth
  alias EHealth.Employee.UserCreateRequest
  alias EHealth.Man.Templates.EmployeeRequestInvitation, as: EmployeeRequestInvitationTemplate
  alias EHealth.Bamboo.Emails.EmployeeRequestInvitation, as: EmployeeRequestInvitationEmail
  alias EHealth.Man.Templates.EmployeeCreatedNotification, as: EmployeeCreatedNotificationTemplate
  alias EHealth.Bamboo.Emails.EmployeeCreatedNotification, as: EmployeeCreatedNotificationEmail
  alias EHealth.API.Mithril
  alias EHealth.Employees
  alias EHealth.BlackListUsers
  alias Ecto.Multi

  require Logger

  @status_new Request.status(:new)
  @status_approved Request.status(:approved)
  @status_rejected Request.status(:rejected)
  @status_expired Request.status(:expired)

  @employee_status_dismissed Employee.status(:dismissed)
  @owner Employee.type(:owner)
  @pharmacy_owner Employee.type(:pharmacy_owner)

  def list(params) do
    query = from er in Request,
      order_by: [desc: :inserted_at]

    paging =
      query
      |> filter_by_legal_entity_id(params)
      |> filter_by_status(params)
      |> Repo.paginate(params)
    legal_entity_ids =
      paging.entries
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

    {paging, %{"legal_entities" => legal_entities}}
  end

  def get_by_id!(id) do
    Repo.get!(Request, id)
  end

  def create(attrs, allowed_owner \\ false) do
    with :ok <- Validator.validate(attrs),
         params <- Map.fetch!(attrs, "employee_request"),
         :ok <- check_owner(params, allowed_owner),
         legal_entity_id <- Map.fetch!(params, "legal_entity_id"),
         %LegalEntity{} = legal_entity <- LegalEntities.get_by_id(legal_entity_id),
         :ok <- validate_type(legal_entity, Map.fetch!(params, "employee_type")),
         :ok <- check_is_user_blacklisted(params)
    do
      insert_employee_request(params)
    else
      nil ->
        {:error, [{%{
          "rule": :invalid,
          "params": [],
          "description": "invalid legal entity"
        }, "$.legal_entity_id"}]}
      err -> err
    end
  end

  def create_user_by_employee_request(params, headers) do
    %Request{data: data} =
      params
      |> Map.fetch!("id")
      |> get_by_id!()

    user_email =
      data
      |> Map.fetch!("party")
      |> Map.fetch!("email")

    %UserCreateRequest{}
    |> changeset(params)
    |> OAuth.create_user(user_email, headers)
  end

  def reject(id) do
    with employee_request <- get_by_id!(id),
         {:ok, employee_request} <- check_transition_status(employee_request)
    do
      update_status(employee_request, @status_rejected)
    end
  end

  def approve(id, headers) do
    employee_request = get_by_id!(id)

    with {:ok, employee_request} <- check_transition_status(employee_request),
         {:ok, employee} <- Employees.create_or_update_employee(employee_request, headers),
         {:ok, employee_request} <- update_status(employee_request, employee, @status_approved)
    do
      send_email(employee_request, EmployeeCreatedNotificationTemplate, EmployeeCreatedNotificationEmail)
    end
  end

  def send_email(%Request{data: data} = employee_request, template, sender) do
    with {:ok, body} <- template.render(employee_request) do
      try do
        data
        |> get_in(["party", "email"])
        |> sender.send(body) # ToDo: use postboy when it is ready
      rescue
        e -> Logger.error(e.message)
      end
      {:ok, employee_request}
    end
  end

  def update_status(%Request{} = employee_request, %Employee{id: id}, status) do
    employee_request
    |> changeset(%{status: status, employee_id: id})
    |> Repo.update()
  end
  def update_status(%Request{} = employee_request, status) do
    employee_request
    |> changeset(%{status: status})
    |> Repo.update()
  end

  def update_all(query, updates) do
    Multi.new
    |> Multi.update_all(:employee_requests, query, set: updates)
    |> Repo.transaction()
  end

  defp filter_by_legal_entity_id(query, %{"legal_entity_id" => legal_entity_id}) do
    where(query, [r], fragment("?->>'legal_entity_id' = ?", r.data, ^legal_entity_id))
  end
  defp filter_by_legal_entity_id(query, _), do: query

  defp filter_by_status(query, %{"status" => status}) when is_binary(status) do
    where(query, [r], r.status == ^status)
  end
  defp filter_by_status(query, _) do
    where(query, [r], r.status == @status_new)
  end

  def check_transition_status(%Request{status: @status_new} = employee_request) do
    {:ok, employee_request}
  end
  def check_transition_status(%Request{status: @status_expired}) do
    {:error, {:forbidden, "Employee request is expired"}}
  end
  def check_transition_status(%Request{status: status}) do
    {:conflict, "Employee request status is #{status} and cannot be updated"}
  end

  defp changeset(%Request{} = schema, attrs) do
    fields = ~W(
      data
      status
      employee_id
    )a

    required_fields = ~W(data status)a

    schema
    |> cast(attrs, fields)
    |> validate_required(required_fields)
    |> validate_data_field(LegalEntity, :legal_entity_id, get_in(attrs, [:data, "legal_entity_id"]))
    |> validate_data_field(Division, :division_id, get_in(attrs, [:data, "division_id"]))
    |> validate_data_field(Employee, :employee_id, get_in(attrs, [:data, "employee_id"]))
  end
  defp changeset(%UserCreateRequest{} = schema, attrs) do
    fields = ~W(
      password
    )a

    schema
    |> cast(attrs, fields)
    |> validate_required(fields)
  end

  defp validate_data_field(changeset, _, _, nil), do: changeset
  defp validate_data_field(changeset, entity, key, id) do
    case PRMRepo.get(entity, id) do
      nil -> add_error(changeset, key, "does not exist")
      _ -> changeset
    end
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
    with %Request{data: data} <- get_by_id!(id) do
      email = get_in(data, ["party", "email"])
      case user_email == email do
        true -> :ok
        _ -> {:error, :forbidden}
      end
    end
  end

  defp insert_employee_request(%{"employee_id" => employee_id} = params) do
    employee = Employees.get_by_id(employee_id)
    if is_nil(employee) do
      {:error, [
        {
          %{
            description: "Employee not found",
            params: [],
            rule: :required
          },
          "$.employee_request.employee_id"
        }
      ]}
    else
      with :ok <- check_tax_id(params, employee),
           :ok <- check_employee_type(params, employee),
           :ok <- check_birth_date(params, employee),
           :ok <- check_start_date(params, employee),
           :ok <- validate_status_type(employee)
      do
        do_insert_employee_request(params)
      end
    end
  end
  defp insert_employee_request(data), do: do_insert_employee_request(data)

  defp do_insert_employee_request(data) do
    with {:ok, request} <-
           %Request{}
           |> changeset(%{data: Map.delete(data, "status"), status: Map.fetch!(data, "status")})
           |> Repo.insert()
    do
      send_email(request, EmployeeRequestInvitationTemplate, EmployeeRequestInvitationEmail)
    end
  end

  def validate_status_type(%Employee{is_active: false}) do
    {:error, :not_found}
  end
  def validate_status_type(%Employee{status: @employee_status_dismissed}) do
    {:error, {:conflict, "employee is dismissed"}}
  end
  def validate_status_type(_), do: :ok

  defp check_tax_id(%{"party" => %{"tax_id" => tax_id}}, employee) do
    case tax_id == employee |> Map.get(:party, %{}) |> Map.get(:tax_id) do
      true -> :ok
      false -> {:error, {:conflict, "tax_id doesn't match"}}
    end
  end

  defp check_employee_type(%{"employee_type" => employee_type}, employee) do
    case employee_type == employee.employee_type do
      true -> :ok
      false -> {:error, {:conflict, "employee_type doesn't match"}}
    end
  end

  defp check_birth_date(%{"party" => party}, employee) do
    case Map.get(party, "birth_date") == to_string(employee.party.birth_date) do
      true -> :ok
      false -> {:error, {:conflict, "birth_date doesn't match"}}
    end
  end

  defp check_start_date(%{"start_date" => start_date}, employee) do
    case start_date == to_string(employee.start_date) do
      true -> :ok
      false -> {:error, {:conflict, "start_date doesn't match"}}
    end
  end

  defp check_is_user_blacklisted(%{"party" => %{"tax_id" => tax_id}}) do
    case BlackListUsers.blacklisted?(tax_id) do
      true -> {:error, {:conflict, "new employee with this tax_id can't be created"}}
      false -> :ok
    end
  end

  defp check_owner(%{"employee_type" => @owner}, false), do: owner_forbidden(@owner)
  defp check_owner(%{"employee_type" => @pharmacy_owner}, false), do: owner_forbidden(@pharmacy_owner)
  defp check_owner(_, _), do: :ok

  defp owner_forbidden(type) do
    {:error, {:conflict, "Forbidden to create #{type}"}}
  end

  defp validate_type(%LegalEntity{type: legal_entity_type}, type) do
    config = Confex.fetch_env!(:ehealth, :legal_entity_employee_types)
    legal_entity_type =
      legal_entity_type
      |> String.downcase()
      |> String.to_atom
    allowed_types = Keyword.get(config, legal_entity_type)
    if Enum.member?(allowed_types, type) do
      :ok
    else
      {:error, [{%{
        "rule": "inclusion",
         "params": allowed_types,
         "description": "value is not allowed in enum"
      }, "$.employee_type"}]}
    end
  end
end
