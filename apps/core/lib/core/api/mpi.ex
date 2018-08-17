defmodule Core.API.MPI do
  @moduledoc """
  MPI API client
  """

  use Core.API.Helpers.MicroserviceBase

  @behaviour Core.API.MPIBehaviour

  def search(params \\ %{}, headers \\ []) do
    get!("/persons", headers, params: params)
  end

  def person(id, headers \\ []) do
    get!("/persons/#{id}", headers)
  end

  def update_person(id, params, headers) do
    patch!("/persons/#{id}", Jason.encode!(params), headers)
  end

  def reset_person_auth_method(id, headers) do
    patch!("/persons/#{id}/actions/reset_auth_method", [], headers)
  end

  def create_or_update_person(params, headers) do
    post("/persons", Jason.encode!(params), headers)
  end

  def create_or_update_person!(params, headers) do
    post!("/persons", Jason.encode!(params), headers)
  end

  def get_merge_candidates(params \\ %{}, headers \\ []) do
    get!("/merge_candidates?#{URI.encode_query(params)}", headers)
  end

  def update_merge_candidate(merge_candidate_id, params, headers \\ []) do
    patch!("/merge_candidates/#{merge_candidate_id}", Jason.encode!(%{merge_candidate: params}), headers)
  end
end
