defmodule EHealth.Employee.EmployeeCreator do
  @moduledoc """
  Creates new employee from valid employee request
  """

  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias EHealth.Employee.Request
  alias EHealth.PRM.Employees
  alias EHealth.PRM.Parties.Schema, as: Party
  alias EHealth.PRM.Employees.Schema, as: Employee
  alias EHealth.PRM.Parties
  alias EHealth.PRM.PartyUsers

  require Logger

  @employee_default_status "APPROVED"
  @employee_type_owner "OWNER"

  def employee_default_status, do: @employee_default_status

  def create(%Request{data: data} = employee_request, req_headers) do
    party = Map.fetch!(data, "party")
    search_params = %{tax_id: party["tax_id"], birth_date: party["birth_date"]}

    with {parties, _} <- Parties.list_parties(search_params),
         {:ok, party} <- create_or_update_party(parties, party, req_headers),
         {:ok, employee} <- create_employee(party, employee_request, req_headers)
    do
      deactivate_employee_owners(employee, req_headers)
    end
  end
  def create(err, _), do: err

  @doc """
  Created new party
  """
  def create_or_update_party([], data, req_headers) do
    with data <- put_inserted_by(data, req_headers),
         {:ok, party} <- Parties.create_party(data)
    do
      create_party_user(party, req_headers)
    end
  end

  @doc """
  Updates party
  """
  def create_or_update_party([%Party{} = party], data, req_headers) do
    with {:ok, party} <- Parties.update_party(party, data) do
      create_party_user(party, req_headers)
    end
  end

  def create_party_user(%Party{id: id, users: users} = party, headers) do
    user_ids = Enum.map(users, &Map.get(&1, :user_id))
    case Enum.member?(user_ids, get_consumer_id(headers)) do
      true ->
        {:ok, party}
      false ->
        case PartyUsers.create_party_user(id, get_consumer_id(headers)) do
          {:ok, _} -> {:ok, party}
          {:error, _} = err -> err
        end
    end
  end

  def create_employee(%Party{id: id}, %Request{data: employee_request}, req_headers) do
    data = %{
      "status" => @employee_default_status,
      "is_active" => true,
      "party_id" => id,
      "legal_entity_id" => employee_request["legal_entity_id"],
    }

    data
    |> Map.merge(employee_request)
    |> put_inserted_by(req_headers)
    |> Employees.create_employee(get_consumer_id(req_headers))
  end
  def create_employee(err, _, _), do: err

  def deactivate_employee_owners(%Employee{employee_type: @employee_type_owner} = employee, req_headers) do
    %{
      legal_entity_id: employee.legal_entity_id,
      is_active: "true",
      employee_type: @employee_type_owner
    }
    |> Employees.get_employees()
    |> deactivate_employees(employee.id, req_headers)
    {:ok, employee}
  end
  def deactivate_employee_owners(%Employee{} = employee, _req_headers), do: {:ok, employee}

  def deactivate_employees({employees, _}, except_employee_id, headers) do
    Enum.each(employees, fn(%Employee{} = employee) ->
      case except_employee_id != employee.id do
        true -> deactivate_employee(employee, headers)
        false -> :ok
      end
    end)
  end

  def deactivate_employee(%Employee{} = employee, headers) do
    params = %{
      "updated_by" => get_consumer_id(headers),
      "is_active" => false,
    }
    Employees.update_employee(employee, params, get_consumer_id(headers))
  end

  def put_inserted_by(data, req_headers) do
    map = %{
      "inserted_by" => get_consumer_id(req_headers),
      "updated_by" => get_consumer_id(req_headers),
    }
    Map.merge(data, map)
  end
end
