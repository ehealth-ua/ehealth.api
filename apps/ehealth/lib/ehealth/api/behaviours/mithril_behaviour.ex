defmodule EHealth.API.MithrilBehaviour do
  @moduledoc false

  # clients
  @callback put_client(params :: map) :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_client(id :: binary) :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_clients() :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_clients(params :: map) :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_client_details(id :: binary, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_client_type_name(id :: binary, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}

  # users
  @callback get_user_by_id(id :: binary, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback search_user(params :: map) :: {:ok, result :: term} | {:error, reason :: term}
  @callback search_user(params :: map, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback create_user(params :: map, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}
  @callback change_user(id :: binary, params :: map, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}

  # user_roles
  @callback get_user_roles(user_id :: binary, params :: map, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback create_user_role(user_id :: binary, params :: map, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}

  # tokens
  @callback create_access_token(user_id :: binary, token :: map, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
end
