defmodule EHealth.Man.Templates.EmployeeRequestInvitation do
  @moduledoc false

  use Confex, otp_app: :ehealth
  alias EHealth.API.Man
  alias EHealth.API.PRM
  alias EHealth.EmployeeRequest
  alias Calendar.DateTime, as: CalendarDateTime
  alias Calendar.Strftime
  alias EHealth.Dictionaries

  def render(%EmployeeRequest{id: id, data: data}) do
    clinic_info =
      data
      |> Map.get("legal_entity_id")
      |> PRM.get_legal_entity_by_id()
      |> get_clinic_info()

    Man.render_template(config()[:id], %{
      format: config()[:format],
      locale: config()[:locale],
      date: current_date("Europe/Kiev", "%d.%m.%y"),
      clinic_name: Map.get(clinic_info, :name),
      clinic_address: Map.get(clinic_info, :address),
      doctor_role: get_position(data),
      request_id: id
    })
  end

  def get_position(data) do
    data
    |> Map.get("position")
    |> Dictionaries.get_dictionary_value("POSITION")
  end

  def get_clinic_info({:error, _}), do: %{}
  def get_clinic_info({:ok, data}) do
    %{
      name: get_in(data, ["data", "name"]),
      address: get_clinic_address(get_in(data, ["data", "addresses"]))
    }
  end

  def get_clinic_address(addresses) when is_list(addresses) and length(addresses) > 0 do
    addresses
    |> Enum.find(fn(x) -> Map.get(x, "type") == "REGISTRATION" end)
    |> merge_address()
  end
  def get_clinic_address(_), do: ""

  def merge_address(nil), do: ""
  def merge_address(address) do
    street = Map.get(address, "street")
    building = Map.get(address, "building")
    settlement = Map.get(address, "settlement")
    zip = Map.get(address, "zip")
    "#{street} #{building}, #{settlement}, #{zip}"
  end

  def current_date(region, format) do
    region
    |> CalendarDateTime.now!()
    |> Strftime.strftime!(format)
  end
end
