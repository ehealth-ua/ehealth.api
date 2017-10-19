defmodule EHealth.API.OPS do
  @moduledoc """
  OPS API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  alias EHealth.API.ResponseDecoder
  alias EHealth.API.Helpers.MicroserviceCallLog, as: CallLog

  def process_url(url), do: config()[:endpoint] <> url

  def timeouts, do: config()[:timeouts]

  def get_declaration_by_id(id, headers) do
    "/declarations/#{id}"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end

  def get_declarations(params, headers \\ []) do
    "/declarations"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def terminate_declarations(employee_id, user_id, headers \\ []) do
    "/employees/#{employee_id}/declarations/actions/terminate"
    |> patch!(Poison.encode!(%{user_id: user_id}), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def terminate_person_declarations(person_id, headers \\ []) do
    full_path = "/persons/#{person_id}/declarations/actions/terminate"

    CallLog.log("PATCH", config()[:endpoint], full_path, %{}, headers)

    full_path
    |> patch!("", headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def create_declaration_with_termination_logic(params, headers \\ []) do
    "/declarations/with_termination"
    |> post!(Poison.encode!(params), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def update_declaration(id, params, headers \\ []) do
    "/declarations/#{id}"
    |> patch!(Poison.encode!(params), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def get_medication_dispenses(params, headers \\ []) do
    "/medication_dispenses"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def create_medication_dispense(params, headers \\ []) do
    "/medication_dispenses"
    |> post!(Poison.encode!(params), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def update_medication_dispense(id, params, headers \\ []) do
    "/medication_dispenses/#{id}"
    |> put!(Poison.encode!(params), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def get_medication_requests(params, headers \\ []) do
    "/medication_requests"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def get_doctor_medication_requests(params, headers \\ []) do
    "/doctor_medication_requests"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def get_qualify_medication_requests(params, headers \\ []) do
    "/qualify_medication_requests"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def create_medication_request(params, headers \\ []) do
    "/medication_requests"
    |> post!(Poison.encode!(params), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def update_medication_request(id, params, headers \\ []) do
    "/medication_requests/#{id}"
    |> patch!(Poison.encode!(params), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def get_latest_block(headers \\ []) do
    "/latest_block"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end
end
