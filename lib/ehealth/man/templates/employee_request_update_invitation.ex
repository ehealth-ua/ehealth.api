defmodule EHealth.Man.Templates.EmployeeRequestUpdateInvitation do
  @moduledoc false

  use Confex, otp_app: :ehealth
  alias EHealth.API.Man
  alias EHealth.LegalEntities
  alias EHealth.Man.Templates.EmployeeRequestInvitation
  alias EHealth.EmployeeRequests.EmployeeRequest, as: Request

  def render(%Request{id: id, data: data}) do
    clinic_info =
      data
      |> Map.get("legal_entity_id")
      |> LegalEntities.get_by_id()
      |> EmployeeRequestInvitation.get_clinic_info()

    Man.render_template(config()[:id], %{
      format: config()[:format],
      locale: config()[:locale],
      date: EmployeeRequestInvitation.current_date("Europe/Kiev", "%d.%m.%y"),
      clinic_name: Map.get(clinic_info, :name),
      clinic_address: Map.get(clinic_info, :address),
      doctor_role: EmployeeRequestInvitation.get_position(data),
      request_id: id |> Cipher.encrypt() |> Base.encode64(),
    })
  end
end
