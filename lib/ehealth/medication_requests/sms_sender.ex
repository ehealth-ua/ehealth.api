defmodule EHealth.MedicationRequests.SMSSender do
  @moduledoc false

  alias EHealth.API.OTPVerification

  def maybe_send_sms(mrr, person, template_fun) do
    otp = Enum.find(person["authentication_methods"], nil, fn method -> method["type"] == "OTP" end)
    if otp do
      {:ok, _} = OTPVerification.send_sms(otp["phone_number"], template_fun.(mrr))
    end
  end

  def sign_template(mrr) do
    Confex.fetch_env!(:ehealth, :medication_request)[:sign_template_sms]
    |> String.replace("<number>", mrr.number)
    |> String.replace("<verification_code>", mrr.verification_code)
  end

  def reject_template(mr) do
    Confex.fetch_env!(:ehealth, :medication_request)[:reject_template_sms]
    |> String.replace("<number>", mr.number)
    |> String.replace("<created_at>", mr.created_at)
  end
end
