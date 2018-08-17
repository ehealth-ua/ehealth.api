defmodule Core.API.MPIBehaviour do
  @moduledoc false

  @callback search(params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback person(id :: binary, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback update_person(id :: binary, params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback reset_person_auth_method(id :: binary, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback create_or_update_person(params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback create_or_update_person!(params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback get_merge_candidates(params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}

  @callback update_merge_candidate(merge_candidate_id :: binary, params :: map, headers :: list) ::
              {:ok, result :: term}
              | {:error, reason :: term}
end
