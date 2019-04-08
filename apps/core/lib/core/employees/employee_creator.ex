defmodule Core.Employees.EmployeeCreator do
  @moduledoc """
  Creates new employee from valid employee request
  """

  import Core.API.Helpers.Connection, only: [get_consumer_id: 1]
  import Ecto.Query

  alias Core.Contracts.ContractSuspender
  alias Core.EmployeeRequests
  alias Core.EmployeeRequests.EmployeeRequest
  alias Core.Employees
  alias Core.Employees.Employee
  alias Core.Employees.EmployeeUpdater
  alias Core.Parties
  alias Core.Parties.Party
  alias Core.PartyUsers
  alias Core.PartyUsers.PartyUser
  alias Core.PRMRepo
  alias Scrivener.Page

  require Logger

  @type_owner Employee.type(:owner)
  @type_pharmacy_owner Employee.type(:pharmacy_owner)
  @status_approved Employee.status(:approved)

  @read_prm_repo Application.get_env(:core, :repos)[:read_prm_repo]

  def create(%EmployeeRequest{data: data} = employee_request, headers) do
    party_params = EmployeeRequests.create_party_params(data)
    search_params = %{tax_id: party_params["tax_id"], birth_date: party_params["birth_date"]}
    user_id = get_consumer_id(headers)

    with %Page{entries: parties} <- Parties.list(search_params),
         :ok <- check_party_user(user_id, parties),
         {:ok, %Party{} = party} <- create_or_update_party(parties, party_params, headers),
         :ok <- Employees.suspend_contracts(Parties.changeset(List.first(parties) || party, party_params)),
         {:ok, {:ok, %Employee{} = employee}} <-
           PRMRepo.transaction(fn ->
             deactivate_employee_owners(
               employee_request.data["employee_type"],
               employee_request.data["legal_entity_id"],
               headers
             )

             create_employee(party, employee_request, headers)
           end) do
      {:ok, employee}
    end
  end

  @doc """
  Created new party
  """
  def create_or_update_party([], data, req_headers) do
    with data <- put_inserted_by(data, req_headers),
         consumer_id = get_consumer_id(req_headers),
         {:ok, party} <- Parties.create(data, consumer_id) do
      create_party_user(party, req_headers)
    end
  end

  @doc """
  Updates party
  """
  def create_or_update_party([%Party{} = party], data, req_headers) do
    consumer_id = get_consumer_id(req_headers)

    with {:ok, party} <- Parties.update(party, data, consumer_id) do
      create_party_user(party, req_headers)
    end
  end

  def create_party_user(%Party{id: id, users: users} = party, headers) do
    user_ids = Enum.map(users, &Map.get(&1, :user_id))
    consumer_id = get_consumer_id(headers)

    case Enum.member?(user_ids, consumer_id) do
      true ->
        {:ok, party}

      false ->
        case PartyUsers.create(id, consumer_id) do
          {:ok, _} -> {:ok, party}
          {:error, _} = err -> err
        end
    end
  end

  def create_employee(%Party{id: id}, %EmployeeRequest{data: employee_request}, req_headers) do
    data = %{
      "status" => @status_approved,
      "is_active" => true,
      "party_id" => id,
      "legal_entity_id" => employee_request["legal_entity_id"],
      "speciality" => EmployeeRequests.get_employee_speciality(employee_request)
    }

    data
    |> Map.merge(employee_request)
    |> put_inserted_by(req_headers)
    |> Employees.create(get_consumer_id(req_headers))
  end

  def create_employee(err, _, _), do: err

  def deactivate_employee_owners(@type_owner, legal_entity_id, req_headers) do
    do_deactivate_employee_owners(legal_entity_id, req_headers)
  end

  def deactivate_employee_owners(@type_pharmacy_owner, legal_entity_id, req_headers) do
    do_deactivate_employee_owners(legal_entity_id, req_headers)
  end

  def deactivate_employee_owners(_, _, _req_headers), do: :ok

  defp do_deactivate_employee_owners(legal_entity_id, req_headers) do
    employees =
      Employee
      |> where([e], e.is_active)
      |> where([e], e.employee_type in ^[@type_owner, @type_pharmacy_owner])
      |> where([e], e.legal_entity_id == ^legal_entity_id)
      |> @read_prm_repo.all()

    suspend_contracts(employees)
    deactivate_employees(employees, req_headers)
  end

  defp suspend_contracts(employees) do
    employee_ids = Enum.map(employees, &Map.get(&1, :id))
    ContractSuspender.suspend_by_contractor_owner_ids(employee_ids)
  end

  def deactivate_employees(employees, headers) do
    params = %{
      "updated_by" => get_consumer_id(headers),
      "is_active" => false
    }

    Enum.each(employees, fn employee ->
      with :ok <- EmployeeUpdater.revoke_user_auth_data(employee, headers) do
        Employees.update(employee, params, get_consumer_id(headers))
      end
    end)
  end

  def deactivate_employee(employee, _), do: {:ok, employee}

  def put_inserted_by(data, req_headers) do
    map = %{
      "inserted_by" => get_consumer_id(req_headers),
      "updated_by" => get_consumer_id(req_headers)
    }

    Map.merge(data, map)
  end

  defp check_party_user(user_id, []) do
    with [] <- PartyUsers.list!(%{user_id: user_id}) do
      :ok
    else
      _ -> {:error, {:conflict, "Email is already used by another person"}}
    end
  end

  defp check_party_user(user_id, [%Party{id: party_id}]) do
    with [] <- PartyUsers.list!(%{user_id: user_id}) do
      :ok
    else
      [%PartyUser{party: %Party{id: id}}] when id == party_id -> :ok
      _ -> {:error, {:conflict, "Email is already used by another person"}}
    end
  end
end
