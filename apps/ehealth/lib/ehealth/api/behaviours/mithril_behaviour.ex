defmodule EHealth.API.MithrilBehaviour do
  @moduledoc false

  # clients
  @callback put_client(params :: map, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_client(id :: binary, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_clients() :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_clients(params :: map) :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_client_details(id :: binary, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_client_type_name(id :: binary, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback refresh_secret(client_id :: binary, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_client_type_by_name(name :: binary, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}

  # users
  @callback get_user_by_id(id :: binary, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback search_user(params :: map, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback create_user(params :: map, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback change_user(id :: binary, params :: map, headers :: list) :: params :: map
  # apps
  @callback delete_apps_by_user_and_client(user_id :: binary, client_id :: binary, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback get_app(id :: binary, params :: map, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_apps(params :: map, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback update_app(params :: map, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback delete_app(id :: binary, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}

  # user_roles
  @callback get_user_roles(user_id :: binary, params :: map, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback create_user_role(user_id :: binary, params :: map, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback create_global_user_role(user_id :: binary, params :: map, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback delete_user_roles_by_user_and_role_name(user_id :: binary, role_name :: binary, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}

  # tokens
  @callback create_access_token(user_id :: binary, token :: map, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback get_roles_by_name(employee_type :: term, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback delete_tokens_by_user_ids(user_ids :: binary, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback delete_tokens_by_user_and_client(user_id :: binary, client_id :: binary, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}

  # auth factors
  @callback get_authentication_factors(user_id :: binary, params :: map, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
end
