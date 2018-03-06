defmodule EHealth.API.MithrilBehaviour do
  @moduledoc false

  # clients
  @callback put_client(params :: map) :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_client(id :: binary) :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_clients() :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_clients(params :: map) :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_client_details(id :: binary) :: {:ok, result :: term} | {:error, reason :: term}
  @callback get_client_type_name(id :: binary, headers :: list) :: {:ok, result :: term} | {:error, reason :: term}

  # users
  @callback search_user(params :: map) :: {:ok, result :: term} | {:error, reason :: term}
end
