defmodule EHealth.API.OPS do
  @moduledoc """
  OPS API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  alias EHealth.API.ResponseDecoder

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
    "/persons/#{person_id}/declarations/actions/terminate"
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
end
