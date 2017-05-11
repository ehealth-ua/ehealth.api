defmodule EHealth.EmployeeRequest.EmployeeCreator do
  @moduledoc """
  Creates new employee from valid employee request
  """

  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias EHealth.EmployeeRequest
  alias EHealth.API.PRM

  @employee_default_status "APPROVED"

  def create(%EmployeeRequest{data: data} = employee_request, req_headers) do
    party = Map.fetch!(data, "party")
    party
    |> Map.fetch!("tax_id")
    |> PRM.get_party_by_tax_id(req_headers)
    |> create_or_update_party(party, req_headers)
    |> create_employee(employee_request, req_headers)
  end
  def create(err, _), do: err

  def create_employee({:ok, %{"data" => %{"id" => id}}}, %EmployeeRequest{data: employee_request}, req_headers) do
    data = %{
      "status" => @employee_default_status,
      "party_id" => id,
      "legal_entity_id" => employee_request["legal_entity_id"],
    }

    data
    |> Map.merge(employee_request)
    |> put_inserted_by(req_headers)
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

  def put_inserted_by(data, req_headers) do
    map = %{
      "inserted_by" => get_consumer_id(req_headers),
      "updated_by" => get_consumer_id(req_headers),
    }
    Map.merge(data, map)
  end
end
