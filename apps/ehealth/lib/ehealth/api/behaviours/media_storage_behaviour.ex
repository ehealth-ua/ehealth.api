defmodule EHealth.API.MediaStorageBehaviour do
  @moduledoc false

  @callback verify_uploaded_file(url :: binary, recource_name :: binary) ::
              {:ok, result :: term} | {:error, reason :: term}

  @callback create_signed_url(
              action :: binary,
              bucket :: binary,
              resource_name :: binary,
              resource_id :: binary,
              headers :: list
            ) :: {:ok, result :: term} | {:error, reason :: term}

  @callback store_signed_content(signed_content :: binary, bucket :: binary, id :: binary, headers :: list) ::
              {:ok, result :: term} | {:error, reason :: term}
end
