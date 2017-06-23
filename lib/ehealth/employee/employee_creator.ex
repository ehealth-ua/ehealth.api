defmodule EHealth.Employee.EmployeeCreator do
  @moduledoc """
  Creates new employee from valid employee request
  """

  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias EHealth.Employee.Request
  alias EHealth.API.PRM

  require Logger

  @employee_default_status "APPROVED"
  @employee_type_owner "OWNER"

  def create(%Request{data: data} = employee_request, req_headers) do
    party = Map.fetch!(data, "party")
    party
    |> PRM.get_party_by_tax_id_and_birth_date(req_headers)
    |> create_or_update_party(party, req_headers)
    |> create_employee(employee_request, req_headers)
    |> deactivate_employee_owners(req_headers)
  end
  def create(err, _), do: err

  @doc """
  Created new party
  """
  def create_or_update_party({:ok, %{"data" => []}}, data, req_headers) do
    data
    |> put_inserted_by(req_headers)
    |> PRM.create_party(req_headers)
    |> create_party_user(req_headers)
  end

  @doc """
  Updates party
  """
  def create_or_update_party({:ok, %{"data" => [%{"id" => id}]}}, data, req_headers) do
    PRM.update_party(data, id, req_headers)
  end

  def create_or_update_party(err, _data, _req_headers), do: err

  def create_party_user({:ok, %{"data" => %{"id" => id}}} = party, req_headers) do
    case PRM.create_party_user(id, get_consumer_id(req_headers), req_headers) do
      {:ok, _} -> party
      {:error, _} = err -> err
    end
  end

  def create_party_user(err, _req_headers), do: err

  def create_employee({:ok, %{"data" => %{"id" => id}}}, %Request{data: employee_request}, req_headers) do
    data = %{
      "status" => @employee_default_status,
      "is_active" => true,
      "party_id" => id,
      "legal_entity_id" => employee_request["legal_entity_id"],
    }

    data
    |> Map.merge(employee_request)
    |> put_inserted_by(req_headers)
    |> PRM.create_employee(req_headers)
  end
  def create_employee(err, _, _), do: err

  def deactivate_employee_owners({:ok, %{"data" => %{"employee_type" => @employee_type_owner} = employee}} = resp,
    req_headers) do
    [
      legal_entity_id: employee["legal_entity_id"],
      is_active: "true",
      employee_type: @employee_type_owner
    ]
    |> PRM.get_employees(req_headers)
    |> deactivate_employees(employee["id"], req_headers, resp)
  end
  def deactivate_employee_owners(err, _req_headers), do: err

  def deactivate_employees({:ok, %{"data" => employees}}, except_employee_id, headers, resp) do
    Enum.each(employees, fn(employee) ->
      case except_employee_id != employee["id"] do
        true -> deactivate_employee(employee["id"], headers)
        false -> :ok
      end
    end)
    resp
  end
  def deactivate_employees(err, _except_employee_id, _headers, _resp), do: err

  def deactivate_employee(id, headers) do
    %{
      "updated_by" => get_consumer_id(headers),
      "is_active" => false,
    }
    |> PRM.update_employee(id, headers)
    |> log_api_response(id)
  end

  defp log_api_response({:ok, _}, _id), do: :ok
  defp log_api_response({:error, reason}, id) do
    Logger.error("Failed to update an employee with id \"#{id}\". Reason: #{inspect reason}")
    :ok
  end

  def put_inserted_by(data, req_headers) do
    map = %{
      "inserted_by" => get_consumer_id(req_headers),
      "updated_by" => get_consumer_id(req_headers),
    }
    Map.merge(data, map)
  end
end
