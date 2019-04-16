defmodule Core.MedicationRequests.SMSSender do
  @moduledoc false

  @otp_verification_api Application.get_env(:core, :api_resolvers)[:otp_verification]

  def maybe_send_sms(mrr, person, template_fun) do
    otp = Enum.find(person.authentication_methods, nil, fn method -> method["type"] == "OTP" end)

    if otp do
      {:ok, _} =
        @otp_verification_api.send_sms(
          %{
            phone_number: otp["phone_number"],
            body: template_fun.(mrr),
            type: "medication_request",
            provider: Confex.fetch_env!(:core, :sms_provider)
          },
          []
        )
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
