defmodule EHealth.EmployeeRequests do
  @moduledoc false

  import Ecto.Query
  import Ecto.Changeset
  import EHealth.Utils.Connection

  alias EHealth.GlobalParameters
  alias EHealth.EmployeeRequests.EmployeeRequest, as: Request
  alias EHealth.Repo
  alias EHealth.Bamboo.Emails.Sender
  alias EHealth.PRMRepo
  alias EHealth.Employees.Employee
  alias EHealth.Divisions.Division
  alias EHealth.LegalEntities
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.EmployeeRequests.Validator
  alias EHealth.OAuth.API, as: OAuth
  alias EHealth.Employee.UserCreateRequest
  alias EHealth.Man.Templates.EmployeeRequestInvitation, as: EmployeeRequestInvitationTemplate
  alias EHealth.Man.Templates.EmployeeRequestUpdateInvitation, as: EmployeeUpdateInvitationTemplate
  alias EHealth.Man.Templates.EmployeeCreatedNotification, as: EmployeeCreatedNotificationTemplate
  alias EHealth.API.Mithril
  alias EHealth.Employees
  alias EHealth.BlackListUsers
  alias EHealth.EventManager

  require Logger

  @status_new Request.status(:new)
  @status_approved Request.status(:approved)
  @status_rejected Request.status(:rejected)
  @status_expired Request.status(:expired)

  @employee_status_dismissed Employee.status(:dismissed)
  @owner Employee.type(:owner)
  @pharmacy_owner Employee.type(:pharmacy_owner)

  def list(params) do
    query = from(er in Request, order_by: [desc: :inserted_at])

    paging =
      query
      |> filter_by_id(params)
      |> filter_by_legal_entity_id(params)
      |> filter_by_legal_entities_params(params)
      |> filter_by_status(params)
      |> filter_by_no_tax_id(params)
      |> Repo.paginate(params)

    legal_entity_ids =
      paging.entries
      |> Enum.reduce([], fn %{data: data}, acc ->
        id = Map.get(data, "legal_entity_id")
        if id, do: [id | acc], else: acc
      end)
      |> Enum.uniq()

    legal_entities =
      LegalEntity
      |> where([le], le.id in ^legal_entity_ids)
      |> PRMRepo.all()
      |> Enum.into(%{}, &{Map.get(&1, :id), &1})

    {paging, %{"legal_entities" => legal_entities}}
  end

  defp filter_by_id(query, %{"id" => id}) do
    where(query, [r], r.id == ^id)
  end

  defp filter_by_id(query, _), do: query

  defp filter_by_legal_entities_params(query, params) do
    if Enum.any?(params, fn {key, _} -> key in ["legal_entity_name", "edrpou"] end) do
      legal_entity_ids =
        LegalEntity
        |> select([l], l.id)
        |> filter_by_legal_entity_name(params["legal_entity_name"])
        |> filter_by_legal_entity_edrpou(params["edrpou"])
        |> PRMRepo.all()

      where(query, [r], fragment("?->>'legal_entity_id'", r.data) in ^legal_entity_ids)
    else
      query
    end
  end

  defp filter_by_legal_entity_name(query, nil), do: query

  defp filter_by_legal_entity_name(query, name) do
    where(query, [l], ilike(l.name, ^("%" <> name <> "%")))
  end

  defp filter_by_legal_entity_edrpou(query, nil), do: query

  defp filter_by_legal_entity_edrpou(query, edrpou) do
    where(query, [l], l.edrpou == ^edrpou)
  end

  defp filter_by_legal_entity_id(query, %{"legal_entity_id" => legal_entity_id}) do
    where(query, [r], fragment("?->>'legal_entity_id' = ?", r.data, ^legal_entity_id))
  end

  defp filter_by_legal_entity_id(query, _), do: query

  defp filter_by_no_tax_id(query, %{"no_tax_id" => no_tax_id}) do
    no_tax_id = cast_boolean(no_tax_id)
    where(query, [r], fragment("?->'party'->'no_tax_id' = ?", r.data, ^no_tax_id))
  end

  defp filter_by_no_tax_id(query, _), do: query

  # ToDo: shit, agreee. It should be Schema for request
  defp cast_boolean(str) when is_boolean(str), do: str
  defp cast_boolean(str) when is_binary(str), do: str |> String.downcase() |> String.to_existing_atom()

  defp filter_by_status(query, %{"status" => status}) when is_binary(status) do
    where(query, [r], r.status == ^status)
  end

  defp filter_by_status(query, _), do: query

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
         :ok <- check_is_user_blacklisted(params) do
      insert_employee_request(params)
    else
      nil ->
        {:error,
         [
           {%{
              rule: :invalid,
              params: [],
              description: "invalid legal entity"
            }, "$.legal_entity_id"}
         ]}

      err ->
        err
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

  def reject(id, headers) do
    user_id = get_consumer_id(headers)

    with employee_request <- get_by_id!(id),
         {:ok, employee_request} <- check_transition_status(employee_request) do
      update_status(employee_request, @status_rejected, user_id)
    end
  end

  def approve(id, headers) do
    employee_request = get_by_id!(id)
    user_id = get_consumer_id(headers)

    with {:ok, employee_request} <- check_transition_status(employee_request),
         {:ok, employee} <- Employees.create_or_update_employee(employee_request, headers),
         {:ok, employee_request} <- update_status(employee_request, employee, @status_approved, user_id) do
      send_email(
        employee_request,
        EmployeeCreatedNotificationTemplate,
        get_email_config(:employee_created_notification)
      )
    end
  end

  def send_email(%Request{data: data} = employee_request, template, email_config) do
    with {:ok, body} <- template.render(employee_request) do
      try do
        data
        |> get_in(["party", "email"])
        |> Sender.send_email(body, email_config[:from], email_config[:subject])
      rescue
        e ->
          Logger.error(fn ->
            Poison.encode!(%{
              "log_type" => "error",
              "message" => e.message,
              "request_id" => Logger.metadata()[:request_id]
            })
          end)
      end

      {:ok, employee_request}
    end
  end

  def update_status(%Request{} = employee_request, %Employee{id: id}, status, user_id) do
    employee_request =
      employee_request
      |> changeset(%{status: status, employee_id: id})
      |> Repo.update()

    with {:ok, employee_request} <- employee_request,
         _ <- EventManager.insert_change_status(employee_request, status, user_id) do
      {:ok, employee_request}
    end
  end

  def update_status(%Request{} = employee_request, status, user_id) do
    employee_request =
      employee_request
      |> changeset(%{status: status})
      |> Repo.update()

    with {:ok, employee_request} <- employee_request,
         _ <- EventManager.insert_change_status(employee_request, status, user_id) do
      {:ok, employee_request}
    end
  end

  def update_all(query, updates, author_id) do
    {_, request_ids} = Repo.update_all(query, [set: updates], returning: [:id, :employee_id])

    max_concurrency = System.schedulers_online() * 2

    request_ids
    |> Task.async_stream(__MODULE__, :insert_events, [updates, author_id], max_concurrency: max_concurrency)
    |> Stream.run()
  end

  def terminate_employee_requests do
    parameters = GlobalParameters.get_values()

    is_valid? =
      Enum.all?(~w(employee_request_expiration employee_request_term_unit), fn param ->
        Map.has_key?(parameters, param)
      end)

    if is_valid? do
      %{
        "employee_request_expiration" => term,
        "employee_request_term_unit" => unit
      } = parameters

      normalized_unit =
        unit
        |> String.downcase()
        |> String.replace_trailing("s", "")

      statuses = Enum.map(~w(approved rejected expired)a, &Request.status/1)

      query =
        Request
        |> where([er], er.status not in ^statuses)
        |> where([er], fragment("?::date < now()::date", datetime_add(er.inserted_at, ^term, ^normalized_unit)))

      update_all(query, [status: Request.status(:expired)], Confex.get_env(:ehealth, :system_user))
    end
  end

  def insert_events(employee_request, [status: status], author_id) do
    EventManager.insert_change_status(employee_request, status, author_id)
    {:ok, employee_request}
  end

  def insert_events(employee_request, _, _) do
    {:ok, employee_request}
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
      {:error,
       [
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
           :ok <- validate_status_type(employee) do
        data = %{
          data: Map.delete(params, "status"),
          status: Map.fetch!(params, "status"),
          employee_id: Map.get(params, "employee_id")
        }

        with {:ok, request} <-
               %Request{}
               |> changeset(data)
               |> Repo.insert() do
          send_email(request, EmployeeUpdateInvitationTemplate, get_email_config(:employee_request_update_invitation))
        end
      end
    end
  end

  defp insert_employee_request(data) do
    data = %{
      data: Map.delete(data, "status"),
      status: Map.fetch!(data, "status"),
      employee_id: Map.get(data, "employee_id")
    }

    with {:ok, request} <-
           %Request{}
           |> changeset(data)
           |> Repo.insert() do
      send_email(request, EmployeeRequestInvitationTemplate, get_email_config(:employee_request_invitation))
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

  defp check_owner(%{"employee_type" => type}, false) when type in [@owner, @pharmacy_owner], do: owner_forbidden(type)
  defp check_owner(_, _), do: :ok

  defp owner_forbidden(type) do
    {:error, {:conflict, "Forbidden to create #{type}"}}
  end

  defp validate_type(%LegalEntity{type: legal_entity_type}, type) do
    config = Confex.fetch_env!(:ehealth, :legal_entity_employee_types)

    legal_entity_type =
      legal_entity_type
      |> String.downcase()
      |> String.to_atom()

    allowed_types = Keyword.get(config, legal_entity_type)

    if Enum.member?(allowed_types, type) do
      :ok
    else
      {:error,
       [
         {%{
            rule: "inclusion",
            params: allowed_types,
            description: "value is not allowed in enum"
          }, "$.employee_type"}
       ]}
    end
  end

  defp get_email_config(type) do
    :ehealth
    |> Confex.fetch_env!(:emails)
    |> Keyword.get(type)
  end
end
