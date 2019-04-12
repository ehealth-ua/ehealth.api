defmodule Core.API.MithrilBehaviour do
  @moduledoc false

  @type api_response :: {:ok, result :: term} | {:error, reason :: term}

  # clients
  @callback put_client(params :: map, headers :: list) :: api_response()
  @callback get_client(id :: binary, headers :: list) :: api_response()
  @callback get_clients() :: api_response()
  @callback get_clients(params :: map) :: api_response()
  @callback get_clients(params :: map, headers :: list) :: api_response()
  @callback get_client_details(id :: binary, headers :: list) :: api_response()
  @callback get_client_type_name(id :: binary, headers :: list) :: api_response()
  @callback get_client_type_by_name(name :: binary, headers :: list) :: api_response()
  @callback deactivate_client_tokens(id :: binary, headers :: list) :: api_response()

  # connections
  @callback get_client_connections(client_id :: binary, params :: map, headers :: list) :: api_response()
  @callback get_client_connection(client_id :: binary, connection_id :: binary, headers :: list) :: api_response()
  @callback upsert_client_connection(client_id :: binary, params :: map, headers :: list) :: api_response()
  @callback update_client_connection(client_id :: binary, connection_id :: binary, params :: map, headers :: list) ::
              api_response()
  @callback delete_client_connection(client_id :: binary, connection_id :: binary, headers :: list) :: api_response()
  @callback refresh_connection_secret(client_id :: binary, connection_id :: binary, headers :: list) :: api_response()

  # users
  @callback get_user_by_id(id :: binary, headers :: list) :: api_response()
  @callback search_user(params :: map, headers :: list) :: api_response()
  @callback create_user(params :: map, headers :: list) :: api_response()
  @callback change_user(id :: binary, params :: map, headers :: list) :: params :: map
  # apps
  @callback delete_apps_by_user_and_client(user_id :: binary, client_id :: binary, headers :: list) :: api_response()
  @callback get_app(id :: binary, params :: map, headers :: list) :: api_response()
  @callback list_apps(params :: map, headers :: list) :: api_response()
  @callback update_app(params :: map, headers :: list) :: api_response()
  @callback delete_app(id :: binary, headers :: list) :: api_response()

  # user_roles
  @callback search_user_roles(params :: map, headers :: list) :: api_response()
  @callback get_user_roles(user_id :: binary, params :: map, headers :: list) :: api_response()
  @callback create_user_role(user_id :: binary, params :: map, headers :: list) :: api_response()
  @callback create_global_user_role(user_id :: binary, params :: map, headers :: list) :: api_response()

  # tokens
  @callback create_access_token(user_id :: binary, token :: map, headers :: list) :: api_response()
  @callback get_roles_by_name(employee_type :: term, headers :: list) :: api_response()
  @callback delete_tokens_by_user_ids(user_ids :: binary, headers :: list) :: api_response()
  @callback delete_tokens_by_user_and_client(user_id :: binary, client_id :: binary, headers :: list) :: api_response()

  # auth factors
  @callback get_authentication_factors(user_id :: binary, params :: map, headers :: list) :: api_response()
end
