defmodule EHealth.API.PRM do
  @moduledoc """
  PRM API client
  """

  require Logger

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.HeadersProcessor

  alias EHealth.API.ResponseDecoder
  alias EHealth.API.Helpers.MicroserviceCallLog, as: CallLog

  def process_url(url), do: config()[:endpoint] <> url

  def timeouts, do: config()[:timeouts]

  # Legal Entity

  def create_legal_entity(data, headers) do
    "/legal_entities"
    |> post!(Poison.encode!(data), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def update_legal_entity(data, id, headers) do
    "/legal_entities/#{id}"
    |> patch!(Poison.encode!(data), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def get_legal_entities(params \\ %{}, headers \\ []) do
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

  # Divisions

  def get_divisions(params \\ [], headers \\ []) do
    "/divisions"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def get_division_by_id(id, headers \\ []) do
    "/divisions/#{id}"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end

  def create_division(params \\ [], headers) do
    "/divisions"
    |> post!(Poison.encode!(params), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def update_division(params, id, headers) do
    "/divisions/#{id}"
    |> patch!(Poison.encode!(params), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  # Party

  def create_party(data, headers) do
    "/party"
    |> post!(Poison.encode!(data), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def update_party(data, id, headers) do
    "/party/#{id}"
    |> patch!(Poison.encode!(data), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  def get_parties(params, headers \\ []) do
    "/party"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def get_party_by_id(id, headers \\ []) do
    "/party/#{id}"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end

  def get_party_by_tax_id_and_birth_date(party, headers \\ []) do
    get_parties([tax_id: Map.fetch!(party, "tax_id"), birth_date: Map.fetch!(party, "birth_date")], headers)
  end

  # Party users

  def get_party_users(params \\ [], headers \\ []) do
    "/party_users"
    |> get!(headers, params: params)
    |> ResponseDecoder.check_response()
  end

  def get_party_users_by_party_id(party_id, headers \\ []) do
    get_party_users([party_id: party_id], headers)
  end

  def create_party_user(party_id, user_id, headers) do
    "/party_users"
    |> post!(Poison.encode!(%{user_id: user_id, party_id: party_id}), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  # Employee

  def create_employee(data, headers) do
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
    CallLog.log("GET", config()[:endpoint], "/employees/#{id}", headers)

    "/employees/#{id}"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end

  def update_employee(data, employee_id, headers) do
    "/employees/#{employee_id}"
    |> patch!(Poison.encode!(data), headers, timeouts())
    |> ResponseDecoder.check_response()
  end

  # Registry

  def check_msp_state_property_status(edrpou, headers \\ []) do
    "/ukr_med_registry"
    |> get!(headers, params: [edrpou: edrpou])
    |> ResponseDecoder.check_response()
  end

  # Global parameters

  def get_global_parameters(headers \\ []) do
    CallLog.log("GET", config()[:endpoint], "/global_parameters", headers)

    "/global_parameters"
    |> get!(headers)
    |> ResponseDecoder.check_response()
  end
end
