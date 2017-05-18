defmodule EHealth.API.PRM do
  @moduledoc """
  PRM API client
  """

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  alias EHealth.API.ResponseDecoder

  def process_url(url), do: config()[:endpoint] <> url

  def timeouts, do: config()[:timeouts]

  # Legal Entity

  def create_legal_entity(data, headers \\ []) do
    "/legal_entities"
    |> post!(Poison.encode!(data), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def update_legal_entity(data, id, headers \\ []) do
    "/legal_entities/#{id}"
    |> patch!(Poison.encode!(data), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def get_legal_entities(params \\ [], headers \\ []) do
    "/legal_entities"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def get_legal_entity_by_id(id, headers \\ []) do
    "/legal_entities/#{id}"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end

  def get_legal_entity_by_edrpou(edrpou, headers \\ []) do
    get_legal_entities([edrpou: edrpou, type: "MSP"], headers)
  end

  # Party

  def create_party(data, headers \\ []) do
    "/party"
    |> post!(Poison.encode!(data), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def update_party(data, id, headers \\ []) do
    "/party/#{id}"
    |> patch!(Poison.encode!(data), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def get_parties(params, headers \\ []) do
    "/party"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def get_party_by_tax_id(edrpou, headers \\ []) do
    get_parties([tax_id: edrpou], headers)
  end

  # Employee

  def create_employee(data, headers \\ []) do
    "/employees"
    |> post!(Poison.encode!(data), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def get_employees(params \\ [], headers \\ []) do
    "/employees"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def get_employee_by_id(id, headers \\ []) do
    "/employees/#{id}"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end

  # Registry

  def check_msp_state_property_status(edrpou, headers \\ []) do
    "/ukr_med_registry"
    |> get!(headers, params: [edrpou: edrpou])
    |> ResponseDecoder.check_response()
  end

  # Division

  def get_division_by_id(id, headers \\ []) do
    "/divisions/#{id}"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end
end
