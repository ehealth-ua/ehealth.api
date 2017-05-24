defmodule EHealth.EmployeeRequest.API do
  @moduledoc false

  use JValid

  import Ecto.{Query, Changeset}, warn: false
  import EHealth.Paging

  alias EHealth.Repo
  alias EHealth.EmployeeRequest
  alias EHealth.Utils.ValidationSchemaMapper
  alias EHealth.EmployeeRequest.EmployeeCreator
  alias EHealth.EmployeeRequest.UserRoleCreator
  alias EHealth.Man.Templates.EmployeeRequestInvitation, as: EmployeeRequestInvitationTemplate
  alias EHealth.Bamboo.Emails.EmployeeRequestInvitation, as: EmployeeRequestInvitationEmail
  alias EHealth.RemoteForeignKeyValidator

  require Logger

  use_schema :employee_request, "specs/json_schemas/new_employee_request_schema.json"

  @status_new "NEW"
  @status_approved "APPROVED"
  @status_rejected "REJECTED"

  def to_integer(value) when is_binary(value), do: String.to_integer(value)
  def to_integer(value), do: value

  def list_employee_requests(params) do
    query = from er in EmployeeRequest,
      order_by: [desc: :inserted_at]

    query
    |> filter_by_legal_entity_id(params)
    |> filter_by_status(params)
    |> Repo.page(get_paging(params, Confex.get(:ehealth, :employee_requests_per_page)))
  end

  defp filter_by_legal_entity_id(query, %{"legal_entity_id" => legal_entity_id}) when is_binary(legal_entity_id) do
    where(query, [r], fragment("?->>'legal_entity_id' = ?", r.data, ^legal_entity_id))
  end
  defp filter_by_legal_entity_id(query, _), do: query

  defp filter_by_status(query, %{"status" => status}) when is_binary(status) do
    where(query, [r], r.status == ^status)
  end
  defp filter_by_status(query, _) do
    where(query, [r], r.status == @status_new)
  end

  def create_employee_request(attrs \\ %{}) do
    schema =
      @schemas
      |> Keyword.get(:employee_request)
      |> ValidationSchemaMapper.prepare_employee_request_schema()

    with :ok <- validate_schema(schema, attrs) do
      data = Map.fetch!(attrs, "employee_request")

      %EmployeeRequest{}
      |> changeset(%{data: Map.delete(data, "status"), status: Map.fetch!(data, "status")})
      |> Repo.insert()
      |> try_send_invitation_email()
    end
  end

  def try_send_invitation_email({:ok, %EmployeeRequest{data: data} = employee_request} = result) do
    email_body = EmployeeRequestInvitationTemplate.render(employee_request)

    try do
      data
      |> get_in(["party", "email"])
      |> EmployeeRequestInvitationEmail.send(email_body) # ToDo: use postboy when it is ready
    rescue
      e -> Logger.error(e.message)
    end
    result
  end
  def try_send_invitation_email(error), do: error

  def reject_employee_request(id) do
    id
    |> get_by_id!()
    |> check_transition_status()
    |> update_status(@status_rejected)
  end

  def approve_employee_request(id, req_headers) do
    employee_request = get_by_id!(id)

    employee_request
    |> check_transition_status()
    |> EmployeeCreator.create(req_headers)
    |> UserRoleCreator.create(req_headers)
    |> update_status(employee_request, @status_approved)
  end

  def check_transition_status(%EmployeeRequest{status: @status_new} = employee_request) do
    employee_request
  end

  def check_transition_status(%EmployeeRequest{status: status}) do
    {:conflict, "Employee request status is #{status} and cannot be updated"}
  end
  def check_transition_status(err), do: err

  def update_status({:ok, _}, %EmployeeRequest{} = employee_request, status) do
    update_status(employee_request, status)
  end
  def update_status(err, _employee_request, _status), do: err

  def update_status(%EmployeeRequest{} = employee_request, status) do
    employee_request
    |> changeset(%{status: status})
    |> Repo.update()
  end
  def update_status(err, _status), do: err

  defp validate_foreign_keys(changeset, attrs) do
    changeset
    |> RemoteForeignKeyValidator.validate(:legal_entity_id, get_in(attrs, [:data, "legal_entity_id"]))
    |> RemoteForeignKeyValidator.validate(:division_id, get_in(attrs, [:data, "division_id"]))
    |> RemoteForeignKeyValidator.validate(:employee_id, get_in(attrs, [:data, "employee_id"]))
  end

  def changeset(%EmployeeRequest{} = schema, attrs) do
    fields = ~W(
      data
      status
    )a

    schema
    |> cast(attrs, fields)
    |> validate_required(fields)
    |> validate_foreign_keys(attrs)
  end

  def get_by_id!(id) do
    Repo.get!(EmployeeRequest, id)
  end
end
