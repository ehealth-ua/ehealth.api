defmodule Core.API.MediaStorageBehaviour do
  @moduledoc false

  @callback verify_uploaded_file(url :: binary, recource_name :: binary) ::
              {:ok, result :: term} | {:error, reason :: term}

  @callback create_signed_url(
              action :: binary,
              bucket :: binary,
              resource_id :: binary,
              headers :: list
            ) :: {:ok, result :: term} | {:error, reason :: term}

  @callback create_signed_url(
              action :: binary,
              bucket :: binary,
              resource_name :: binary,
              resource_id :: binary,
              headers :: list
            ) :: {:ok, result :: term} | {:error, reason :: term}

  @callback store_signed_content(
              signed_content :: binary,
              bucket :: binary,
              id :: binary,
              resource_name :: binary,
              headers :: list
            ) :: {:ok, result :: term} | {:error, reason :: term}

  @callback get_signed_content(url :: binary) :: {:ok, result :: term} | {:error, reason :: term}
  @callback save_file(id :: binary, content :: binary, bucket :: binary, resource_name :: binary, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
  @callback delete_file(url :: binary) :: {:ok, result :: term} | {:error, reason :: term}

  @callback put_signed_content(url :: binary, content :: binary, headers :: list, options :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
end
