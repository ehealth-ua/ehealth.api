defmodule Core.API.Mithril do
  @moduledoc """
  Trump API client
  API documentation: http://docs.trump1.apiary.io
  """

  use Core.API.Helpers.MicroserviceBase

  @behaviour Core.API.MithrilBehaviour

  # Clients

  def put_client(%{"id" => id} = params, headers \\ []) do
    put!("/admin/clients/#{id}", Jason.encode!(%{"client" => params}), headers)
  end

  def get_client(id, headers \\ []) do
    get!("/admin/clients/#{id}", headers)
  end

  def get_clients(params \\ [], headers \\ []) do
    get!("/admin/clients", headers, params: params)
  end

  def get_client_details(id, headers \\ []) do
    get!("/admin/clients/#{id}/details", headers)
  end

  def get_client_type_name(id, headers) do
    case get_client_details(id, headers) do
      {:ok, %{"data" => %{"client_type_name" => client_type}}} -> {:ok, client_type}
      _ -> {:error, :access_denied}
    end
  end

  def deactivate_client_tokens(id, headers \\ []) do
    patch!("/admin/clients/#{id}/actions/deactivate_tokens", "", headers)
  end

  # client connections

  def get_client_connections(client_id, params \\ [], headers \\ []) do
    get!("/admin/clients/#{client_id}/connections", headers, params: params)
  end

  def get_client_connection(client_id, connection_id, headers) do
    get!("/admin/clients/#{client_id}/connections/#{connection_id}", headers)
  end

  def upsert_client_connection(client_id, params, headers) do
    put!("/admin/clients/#{client_id}/connections", Jason.encode!(params), headers)
  end

  def update_client_connection(client_id, connection_id, params, headers) do
    patch!("/admin/clients/#{client_id}/connections/#{connection_id}", Jason.encode!(params), headers)
  end

  def delete_client_connection(client_id, connection_id, headers) do
    delete!("/admin/clients/#{client_id}/connections/#{connection_id}", headers)
  end

  def refresh_connection_secret(client_id, connection_id, headers) do
    patch!("/admin/clients/#{client_id}/connections/#{connection_id}/actions/refresh_secret", "", headers)
  end

  # Client types

  def create_client_type(client_type, headers \\ []) do
    post!("/admin/client_types", Jason.encode!(%{"client_type" => client_type}), headers)
  end

  def get_client_types(params \\ [], headers \\ []) do
    get!("/admin/client_types", headers, params: params)
  end

  def get_client_type_by_name(name, headers \\ []) do
    get_client_types([name: name], headers)
  end

  # Users

  def get_user_by_id(id, headers \\ []) do
    get!("/admin/users/#{id}", headers)
  end

  def search_user(params, headers \\ []) do
    get!("/admin/users", headers, params: params)
  end

  def create_user(params, headers \\ []) do
    post!("/admin/users", Jason.encode!(%{"user" => params}), headers)
  end

  def change_user(id, attrs, headers \\ []) do
    put!("/admin/users/#{id}", Jason.encode!(%{"user" => attrs}), headers)
  end

  # Roles

  def get_roles_by_name(name, headers \\ []) do
    get!("/admin/roles", headers, params: [name: name])
  end

  # User roles

  def search_user_roles(params, headers \\ []) do
    get!("/admin/user_roles", headers, params: params)
  end

  def get_user_roles(user_id, params, headers \\ []) when is_binary(user_id) do
    get!("/admin/users/#{user_id}/roles", headers, params: params)
  end

  def create_user_role(user_id, role, headers \\ []) do
    post!("/admin/users/#{user_id}/roles", Jason.encode!(%{"user_role" => role}), headers)
  end

  def create_global_user_role(user_id, role, headers \\ []) do
    post!("/admin/users/#{user_id}/global_roles", Jason.encode!(%{"global_user_role" => role}), headers)
  end

  def delete_user_role(user_id, role_id, headers) do
    delete!("/admin/users/#{user_id}/roles/#{role_id}", headers)
  end

  # Apps

  def get_app(id, headers \\ [], params) do
    get!("/admin/apps/#{id}", headers, params: params)
  end

  def list_apps(params \\ [], headers \\ []) do
    get!("/admin/apps", headers, params: params)
  end

  def update_app(headers, %{"id" => id} = params) do
    put!("/admin/apps/#{id}", headers, params: params)
  end

  def delete_app(app_id, headers) do
    delete!("/admin/apps/#{app_id}", headers)
  end

  def delete_apps_by_user_and_client(user_id, client_id, headers) do
    delete!("/admin/users/#{user_id}/apps?client_id=#{client_id}", headers)
  end

  # Tokens

  def get_tokens(params \\ [], headers \\ []) do
    get!("/admin/tokens", headers, params: params)
  end

  def create_access_token(user_id, token, headers) do
    post!("/admin/users/#{user_id}/tokens/access", Jason.encode!(%{token: token}), headers)
  end

  def delete_token(token_id, headers) do
    delete!("/admin/tokens/#{token_id}", headers)
  end

  def delete_tokens_by_user_and_client(user_id, client_id, headers) do
    delete!("/admin/users/#{user_id}/tokens?client_id=#{client_id}", headers)
  end

  def delete_tokens_by_user_ids(user_ids, headers) do
    delete!("/admin/tokens?user_ids=#{user_ids}", headers)
  end

  # Authentication factors

  def get_authentication_factors(user_id, params, headers \\ []) do
    get!("/admin/users/#{user_id}/authentication_factors", headers, params: params)
  end
end
