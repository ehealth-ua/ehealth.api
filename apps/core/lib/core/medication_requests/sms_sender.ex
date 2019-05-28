defmodule Core.MedicationRequests.SMSSender do
  @moduledoc false

  @rpc_worker Application.get_env(:core, :rpc_worker)

  def maybe_send_sms(mrr, person, template_fun) do
    otp = Enum.find(person.authentication_methods, nil, fn method -> method.type == "OTP" end)

    if otp do
      {:ok, _} =
        @rpc_worker.run("otp_verification_api", OtpVerification.Rpc, :send_sms, [
          otp["phone_number"],
          template_fun.(mrr),
          "medication_request",
          Confex.fetch_env!(:core, :sms_provider)
        ])
    end
  end

  def sign_template(mrr) do
    Confex.fetch_env!(:core, :medication_request)[:sign_template_sms]
    |> String.replace("<request_number>", mrr.request_number)
    |> String.replace("<verification_code>", mrr.verification_code)
  end

  def reject_template(mr) do
    Confex.fetch_env!(:core, :medication_request)[:reject_template_sms]
    |> String.replace("<request_number>", mr.request_number)
    |> String.replace("<created_at>", mr.created_at)
  end
end
