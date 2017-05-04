defmodule EHealth.EmployeeRequest.API do
  @moduledoc false

  use JValid

  import Ecto.{Query, Changeset}, warn: false

  alias EHealth.Repo
  alias EHealth.EmployeeRequest
  alias EHealth.API.PRM

  use_schema :employee_request, "specs/json_schemas/new_employee_request_schema.json"

  @status_approved "APPROVED"
  @status_rejected "REJECTED"

  def create_employee_request(attrs \\ %{}) do
    with :ok <- validate_schema(:employee_request, attrs) do
      data = Map.fetch!(attrs, "employee_request")
      Repo.insert(%EmployeeRequest{data: data, status: Map.fetch!(data, "status")})
    end
  end

  def approve_employee_request(id, req_headers) do
    employee_request = get_by_id!(id)

    employee_request
    |> create_employee(req_headers)
    |> update_status(employee_request, @status_approved)
  end

  def create_employee(%EmployeeRequest{data: data} = employee_request, req_headers) do
    party = Map.fetch!(data, "party")
    party
    |> Map.fetch!("tax_id")
    |> PRM.get_party_by_tax_id(req_headers)
    |> create_or_update_party(party, req_headers)
    |> create_employee(employee_request, req_headers)
  end
  def create_employee(err, _), do: err

  def create_employee({:ok, %{"data" => %{"id" => id}}}, %EmployeeRequest{data: employee_request}, req_headers) do
    data = %{
      "party_id" => id,
      "legal_entity_id" => employee_request["legal_entity_id"],
    }

    employee_request
    |> put_inserted_by(req_headers)
    |> Map.merge(data)
    |> PRM.create_employee(req_headers)
  end
  def create_employee(err, _, _), do: err

  @doc """
  Created new party
  """
  def create_or_update_party({:ok, %{"data" => []}}, data, req_headers) do
    data
    |> put_inserted_by(req_headers)
    |> PRM.create_party(req_headers)
  end

  @doc """
  Updates party
  """
  def create_or_update_party({:ok, %{"data" => [%{"id" => id}]}}, data, req_headers) do
    PRM.update_party(data, id, req_headers)
  end

  def create_or_update_party(err, _data, _req_headers), do: err

  def reject_employee_request(id) do
    update_status(id, @status_rejected)
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

  def put_inserted_by(data, req_headers) do
    map = %{
      "inserted_by" => get_consumer_id(req_headers),
      "updated_by" => get_consumer_id(req_headers),
    }
    Map.merge(data, map)
  end

  def get_consumer_id(headers) do
    list = for {k, v} <- headers, k == "x-consumer-id", do: v
    List.first(list)
  end
end
