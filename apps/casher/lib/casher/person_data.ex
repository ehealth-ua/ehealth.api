defmodule Casher.PersonData do
  @moduledoc false

  import Ecto.Query

  alias Casher.Redis
  alias Casher.StorageKeys
  alias Core.Employees.Employee
  alias Core.PartyUsers.PartyUser
  alias Core.PRMRepo

  @ops_client Application.get_env(:core, :api_resolvers)[:ops]

  @spec get_and_update(map) :: {:ok, [binary]} | {:error, term}
  def get_and_update(%{user_id: user_id, client_id: client_id}) do
    with {:ok, party_id} <- get_party_id(user_id),
         employee_ids <- get_employee_ids(party_id, client_id),
         {:ok, person_ids} <- update_cache(client_id, party_id, employee_ids) do
      {:ok, person_ids}
    end
  end

  def get_and_update(%{employee_id: employee_id}) do
    with %Employee{legal_entity_id: client_id, party_id: party_id} <- get_employee(employee_id),
         employee_ids <- get_employee_ids(party_id, client_id),
         {:ok, person_ids} <- update_cache(client_id, party_id, employee_ids) do
      {:ok, person_ids}
    end
  end

  @spec update_cache(binary, binary, [binary]) :: {:ok, [binary]} | {:error, term}
  defp update_cache(client_id, party_id, employee_ids) when is_list(employee_ids) do
    with {:ok, %{"data" => %{"person_ids" => person_ids}}} <- @ops_client.get_person_ids(employee_ids, []) do
      party_id
      |> get_user_ids()
      |> Enum.each(&update_redis(&1, client_id, person_ids))

      {:ok, person_ids}
    end
  end

  @spec get_user_ids(binary) :: [binary]
  defp get_user_ids(party_id) do
    PartyUser
    |> select([pu], pu.user_id)
    |> where([pu], pu.party_id == ^party_id)
    |> PRMRepo.all()
  end

  @spec get_party_id(binary) :: {:ok, binary} | {:error, binary}
  defp get_party_id(user_id) do
    PartyUser
    |> select([pu], pu.party_id)
    |> where([pu], pu.user_id == ^user_id)
    |> PRMRepo.one()
    |> case do
      party_id when is_binary(party_id) -> {:ok, party_id}
      _ -> {:error, {:not_found, "PartyUser not found."}}
    end
  end

  @spec get_employee(binary) :: %Employee{} | {:error, term}
  def get_employee(employee_id) do
    Employee
    |> PRMRepo.get(employee_id)
    |> case do
      %Employee{} = employee -> employee
      _ -> {:error, {:not_found, "Employee not found."}}
    end
  end

  @spec get_employee_ids(binary, binary) :: [binary]
  defp get_employee_ids(party_id, client_id) do
    Employee
    |> select([e], e.id)
    |> where([e], e.party_id == ^party_id)
    |> where([e], e.legal_entity_id == ^client_id)
    |> PRMRepo.all()
  end

  @spec update_redis(binary, binary, [binary]) :: :ok | {:error, term}
  defp update_redis(user_id, client_id, person_ids) do
    redis_key = StorageKeys.person_data(user_id, client_id)
    ttl = Confex.fetch_env!(:casher, :cache_ttl)[:person_data]

    Redis.setex(redis_key, ttl, person_ids)
  end
end
