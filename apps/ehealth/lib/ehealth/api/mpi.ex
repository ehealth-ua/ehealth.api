defmodule EHealth.API.MPI do
  @moduledoc """
  MPI API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor
  use EHealth.API.Helpers.MicroserviceBase

  # Available params (required):
  #   - first_name (ex.: Олена)
  #   - last_name (ex.: Пчілка)
  #   - birth_date (ex.: 1991-08-19%2000:00:00)
  #   - tax_id (ex.: 3126509816)
  #   - phone_number (ex.: %2B380508887700)
  #
  def search(params \\ %{}, headers \\ []) do
    get!("/persons", headers, params: params)
  end

  def all_search(params \\ %{}, headers \\ []) do
    get!("/all-persons", headers, params: params)
  end

  def admin_search(params \\ %{}, headers \\ []) do
    get!("/persons_internal", headers, params: params)
  end

  def person(id, headers \\ []) do
    get!("/persons/#{id}", headers)
  end

  def update_person(id, params, headers) do
    patch!("/persons/#{id}", Poison.encode!(params), headers)
  end

  def reset_person_auth_method(id, headers) do
    patch!("/persons/#{id}/actions/reset_auth_method", [], headers)
  end

  def create_or_update_person(params, headers) do
    post!("/persons", Poison.encode!(params), headers)
  end

  def get_merge_candidates(params \\ %{}, headers \\ []) do
    get!("/merge_candidates?#{URI.encode_query(params)}", headers)
  end

  def update_merge_candidate(merge_candidate_id, params, headers \\ []) do
    patch!("/merge_candidates/#{merge_candidate_id}", Poison.encode!(%{merge_candidate: params}), headers)
  end
end
