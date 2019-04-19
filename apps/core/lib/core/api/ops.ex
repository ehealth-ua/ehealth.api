defmodule Core.API.OPS do
  @moduledoc """
  OPS API client
  """

  use Core.API.Helpers.MicroserviceBase

  @behaviour Core.API.OPSBehaviour

  def get_declaration_by_id(id, headers) do
    get!("/declarations/#{id}", headers)
  end

  def get_declarations(params, headers \\ []) do
    get!("/declarations", headers, params: params)
  end

  def get_person_ids(employee_ids, headers \\ []) when is_list(employee_ids) do
    post!("/declarations/person_ids", Jason.encode!(%{"employee_ids" => employee_ids}), headers)
  end

  def get_declarations_count(params, headers \\ []) do
    post!("/declarations_count", Jason.encode!(params), headers)
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

  def process_medication_dispense(id, params, headers \\ []) do
    patch!("/medication_dispenses/#{id}/process", Jason.encode!(params), headers)
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

  def get_latest_block(headers \\ []) do
    get!("/latest_block", headers)
  end
end
