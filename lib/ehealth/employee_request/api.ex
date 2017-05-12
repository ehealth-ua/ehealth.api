defmodule EHealth.EmployeeRequest.API do
  @moduledoc false

  use JValid

  import Ecto.{Query, Changeset}, warn: false

  alias EHealth.Repo
  alias EHealth.EmployeeRequest
  alias EHealth.EmployeeRequest.EmployeeCreator
  alias EHealth.Man.Templates.EmployeeRequestInvitation, as: EmployeeRequestInvitationTemplate
  alias EHealth.Bamboo.Emails.EmployeeRequestInvitation, as: EmployeeRequestInvitationEmail

  require Logger

  use_schema :employee_request, "specs/json_schemas/new_employee_request_schema.json"

  @status_approved "APPROVED"
  @status_rejected "REJECTED"

  def to_integer(value) when is_binary(value), do: String.to_integer(value)
  def to_integer(value), do: value

  def list_employee_requests(params) do
    limit =
      params
      |> Map.get("limit", Confex.get(:ehealth, :employee_requests_per_page))
      |> to_integer()

    cursors = %Ecto.Paging.Cursors{
      starting_after: Map.get(params, "starting_after"),
      ending_before: Map.get(params, "ending_before")
    }

    query = from er in EmployeeRequest,
      order_by: [desc: :inserted_at]

    Repo.page(query, %Ecto.Paging{limit: limit, cursors: cursors})
  end

  def create_employee_request(attrs \\ %{}) do
    with :ok <- validate_schema(:employee_request, attrs) do
      data = Map.fetch!(attrs, "employee_request")

      %EmployeeRequest{data: Map.delete(data, "status"), status: Map.fetch!(data, "status")}
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
    update_status(id, @status_rejected)
  end

  def approve_employee_request(id, req_headers) do
    employee_request = get_by_id!(id)

    employee_request
    |> EmployeeCreator.create(req_headers)
    |> update_status(employee_request, @status_approved)
  end

  def update_status(id, status) when is_binary(id) do
    id
    |> get_by_id!()
    |> changeset(%{status: status})
    |> Repo.update()
  end

  def update_status({:ok, _}, %EmployeeRequest{} = employee_request, status) do
    employee_request
    |> changeset(%{status: status})
    |> Repo.update()
  end

  def update_status(err, _employee_request, _status), do: err

  def changeset(%EmployeeRequest{} = schema, attrs) do
    fields = ~W(
      data
      status
    )a

    schema
    |> cast(attrs, fields)
    |> validate_required(fields)
  end

  def get_by_id!(id) do
    Repo.get!(EmployeeRequest, id)
  end
end
