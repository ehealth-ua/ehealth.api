defmodule EHealth.API.OPS do
  @moduledoc """
  OPS API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor
  use EHealth.API.Helpers.MicroserviceBase

  def get_declaration_by_id(id, headers) do
    get!("/declarations/#{id}", headers)
  end

  def get_declarations(params, headers \\ []) do
    get!("/declarations", headers, params: params)
  end

  def terminate_employee_declarations(employee_id, user_id, reason, reason_description \\ "", headers \\ []) do
    body = Poison.encode!(%{user_id: user_id, reason: reason, reason_description: reason_description})
    patch!("/employees/#{employee_id}/declarations/actions/terminate", body, headers)
  end

  def terminate_person_declarations(person_id, user_id, reason, reason_description \\ "", headers \\ []) do
    body = Poison.encode!(%{user_id: user_id, reason: reason, reason_description: reason_description})
    patch!("/persons/#{person_id}/declarations/actions/terminate", body, headers)
  end

  def create_declaration_with_termination_logic(params, headers \\ []) do
    post!("/declarations/with_termination", Poison.encode!(params), headers)
  end

  def update_declaration(id, params, headers \\ []) do
    patch!("/declarations/#{id}", Poison.encode!(params), headers)
  end

  def get_medication_dispenses(params, headers \\ []) do
    get!("/medication_dispenses", headers, params: params)
  end

  def create_medication_dispense(params, headers \\ []) do
    post!("/medication_dispenses", Poison.encode!(params), headers)
  end

  def update_medication_dispense(id, params, headers \\ []) do
    put!("/medication_dispenses/#{id}", Poison.encode!(params), headers)
  end

  def get_medication_requests(params, headers \\ []) do
    get!("/medication_requests", headers, params: params)
  end

  def get_doctor_medication_requests(params, headers \\ []) do
    post!("/doctor_medication_requests", Poison.encode!(params), headers)
  end

  def get_qualify_medication_requests(params, headers \\ []) do
    get!("/qualify_medication_requests", headers, params: params)
  end

  def get_prequalify_medication_requests(params, headers \\ []) do
    get!("/prequalify_medication_requests", headers, params: params)
  end

  def create_medication_request(params, headers \\ []) do
    post!("/medication_requests", Poison.encode!(params), headers)
  end

  def update_medication_request(id, params, headers \\ []) do
    patch!("/medication_requests/#{id}", Poison.encode!(params), headers)
  end

  def get_latest_block(headers \\ []) do
    get!("/latest_block", headers)
  end
end
