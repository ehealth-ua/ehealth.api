defmodule EHealth.API.OPS do
  @moduledoc """
  OPS API client
  """

  use EHealth.API.Helpers.MicroserviceBase

  @behaviour EHealth.API.OPSBehaviour

  def get_declaration_by_id(id, headers) do
    get!("/declarations/#{id}", headers)
  end

  def get_declarations(params, headers \\ []) do
    get!("/declarations", headers, params: params)
  end

  def get_declarations_count(employee_ids, headers \\ []) do
    post!("/declarations_count", Jason.encode!(%{ids: employee_ids}), headers)
  end

  def terminate_declaration(id, params, headers \\ []) do
    patch!("/declarations/#{id}/actions/terminate", Jason.encode!(params), headers)
  end

  def terminate_employee_declarations(employee_id, user_id, reason, reason_description \\ "", headers \\ []) do
    body = Jason.encode!(%{user_id: user_id, reason: reason, reason_description: reason_description})
    patch!("/employees/#{employee_id}/declarations/actions/terminate", body, headers)
  end

  def terminate_person_declarations(person_id, user_id, reason, reason_description \\ "", headers \\ []) do
    body = Jason.encode!(%{user_id: user_id, reason: reason, reason_description: reason_description})
    patch!("/persons/#{person_id}/declarations/actions/terminate", body, headers)
  end

  def create_declaration_with_termination_logic(params, headers \\ []) do
    post!("/declarations/with_termination", Jason.encode!(params), headers)
  end

  def update_declaration(id, params, headers \\ []) do
    patch!("/declarations/#{id}", Jason.encode!(params), headers)
  end

  def get_medication_dispenses(params, headers \\ []) do
    get!("/medication_dispenses", headers, params: params)
  end

  def create_medication_dispense(params, headers \\ []) do
    post!("/medication_dispenses", Jason.encode!(params), headers)
  end

  def update_medication_dispense(id, params, headers \\ []) do
    put!("/medication_dispenses/#{id}", Jason.encode!(params), headers)
  end

  def get_medication_requests(params, headers \\ []) do
    get!("/medication_requests", headers, params: params)
  end

  def get_doctor_medication_requests(params, headers \\ []) do
    post!("/doctor_medication_requests", Jason.encode!(params), headers)
  end

  def get_qualify_medication_requests(params, headers \\ []) do
    get!("/qualify_medication_requests", headers, params: params)
  end

  def get_prequalify_medication_requests(params, headers \\ []) do
    get!("/prequalify_medication_requests", headers, params: params)
  end

  def create_medication_request(params, headers \\ []) do
    post!("/medication_requests", Jason.encode!(params), headers)
  end

  def update_medication_request(id, params, headers \\ []) do
    patch!("/medication_requests/#{id}", Jason.encode!(params), headers)
  end

  def create_contract(params, headers \\ []) do
    post!("/contracts", Poison.encode!(params), headers)
  end

  def get_contract(id, headers \\ []) do
    get!("/contracts/#{id}", headers)
  end

  def get_contracts(params, headers \\ []) do
    get!("/contracts/", headers, params: params)
  end

  def get_latest_block(headers \\ []) do
    get!("/latest_block", headers)
  end

  def suspend_contracts(ids, headers) when is_list(ids) do
    params = %{ids: Enum.join(ids, ",")}
    patch!("/contracts/actions/suspend", Jason.encode!(params), headers)
  end

  def renew_contracts(ids, headers) when is_list(ids) do
    params = %{ids: Enum.join(ids, ",")}
    patch!("/contracts/actions/renew", Jason.encode!(params), headers)
  end
end
