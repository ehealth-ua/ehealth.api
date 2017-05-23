defmodule EHealth.EmployeeRequest.UserRoleCreator do
  @moduledoc """
  Creates or updates user roles in Mithril
  """
  use OkJose

  import EHealth.Utils.Pipeline

  alias EHealth.API.PRM
  alias EHealth.API.Mithril

  require Logger

  def create({:ok, %{"data" => employee}}, headers) do
    {:ok, %{
      party_id: Map.fetch!(employee, "party_id"),
      client_id: Map.fetch!(employee, "legal_entity_id"),
      employee: employee,
      headers: headers
    }}
    |> get_prm_party_users_by_party_id()
    |> get_oauth_roles()
    |> find_role_id_by_employee_type()
    |> add_oauth_users_role()
    |> ok()
    |> normalize_resp()
  end
  def create(err, _headers), do: err

  def get_prm_party_users_by_party_id(pipe_data) do
    pipe_data
    |> Map.fetch!(:party_id)
    |> PRM.get_party_users_by_party_id(Map.fetch!(pipe_data, :headers))
    |> put_success_api_response_in_pipe(:party_users, pipe_data)
  end

  def get_oauth_roles(pipe_data) do
    pipe_data
    |> Map.fetch!(:employee)
    |> Map.fetch!("employee_type")
    |> Mithril.get_roles_by_name(Map.fetch!(pipe_data, :headers))
    |> put_success_api_response_in_pipe(:roles, pipe_data)
  end

  def find_role_id_by_employee_type(%{roles: %{"data" => []}}) do
    {:error, :invalid_role}
  end

  def find_role_id_by_employee_type(%{roles: %{"data" => roles}} = pipe_data) do
    roles
    |> List.first()
    |> Map.fetch!("id")
    |> put_in_pipe(:role_id, pipe_data)
  end

  def add_oauth_users_role(%{party_users: %{"data" => party_users}} = pipe_data) when length(party_users) > 0 do
    role_id = Map.fetch!(pipe_data, :role_id)
    client_id = Map.fetch!(pipe_data, :client_id)
    headers = Map.fetch!(pipe_data, :headers)

    Enum.each(party_users, fn(%{"user_id" => user_id}) ->
      user_id
      |> Mithril.get_user_roles(role_id, headers)
      |> create_user_role(user_id, role_id, client_id, headers)
      |> validate_api_response(pipe_data, "Failed to add role '#{role_id}' to user '#{user_id}'.")
    end)

    {:ok, pipe_data}
  end
  def add_oauth_users_role(%{party_users: %{"data" => _}, party_id: party_id} = pipe_data) do
    Logger.error(fn ->
      "Empty party users by party_id #{party_id}. Cannot create new roles"
    end)
    {:ok, pipe_data}
  end

  @doc """
  User role doen't exists. Creates new user role
  """
  def create_user_role({:ok, %{"data" => []}}, user_id, role_id, client_id, headers) do
    role = %{
      "role_id" => role_id,
      "client_id" => client_id,
    }
    Mithril.create_user_role(user_id, role, headers)
  end

  @doc """
  User role exists. Skip creation
  """
  def create_user_role({:ok, _}, _user_id, _role_id, _client_id, _headers), do: :ok

  @doc """
  Failed to get User roles from OAuth. Ignored and creates new role for user.
  """
  def create_user_role({:error, reason}, user_id, role_id, client_id, headers) do
    Logger.error(fn ->
      "Cannot get user roles for user #{user_id}. Creates role for user. Response: #{inspect reason}"
    end)
    create_user_role({:ok, %{"data" => []}}, user_id, role_id, client_id, headers)
  end

  def normalize_resp({:error, _} = err), do: err
  def normalize_resp(resp), do: {:ok, resp}
end
