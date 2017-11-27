defmodule EHealth.API.Mithril do
  @moduledoc """
  Trump API client
  API documentation: http://docs.trump1.apiary.io
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor
  use EHealth.API.Helpers.MicroserviceBase

  # Clients

  def put_client(%{"id" => id} = params, headers \\ []) do
    put!("/admin/clients/#{id}", Poison.encode!(%{"client" => params}), headers)
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
    id
    |> get_client_details(headers)
    |> case do
         {:ok, %{"data" => %{"client_type_name" => client_type}}} -> {:ok, client_type}
         _ -> {:error, :access_denied}
       end
  end

  # Client types

  def create_client_type(client_type, headers \\ []) do
    post!("/admin/client_types", Poison.encode!(%{"client_type" => client_type}), headers)
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
    post!("/admin/users", Poison.encode!(%{"user" => params}), headers)
  end

  def change_user(id, attrs, headers \\ []) do
    put!("/admin/users/#{id}", Poison.encode!(%{"user" => attrs}), headers)
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
    post!("/admin/users/#{user_id}/roles", Poison.encode!(%{"user_role" => role}), headers)
  end

  def delete_user_role(user_id, role_id, headers) do
    delete!("/admin/users/#{user_id}/roles/#{role_id}", headers)
  end

  def delete_user_roles_by_user_and_role_name(user_id, role_name, headers) do
    delete!("/admin/users/#{user_id}/roles?role_name=#{role_name}", headers)
  end

  # Apps

  def get_apps(params \\ [], headers \\ []) do
    get!("/admin/apps", headers, params: params)
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

  def delete_token(token_id, headers) do
    delete!("/admin/tokens/#{token_id}", headers)
  end

  def delete_tokens_by_user_and_client(user_id, client_id, headers) do
    delete!("/admin/users/#{user_id}/tokens?client_id=#{client_id}", headers)
  end

  def delete_tokens_by_user_ids(user_ids, headers) do
    delete!("/admin/tokens?user_ids=#{user_ids}", headers)
  end

  def refresh_secret(client_id, headers) do
    patch!("/admin/clients/#{client_id}/refresh_secret", "", headers)
  end
end
