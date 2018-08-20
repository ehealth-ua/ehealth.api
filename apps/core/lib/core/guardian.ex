defmodule Core.Guardian do
  @moduledoc false

  use Guardian, otp_app: :core

  @aud_registration "cabinet-registration"
  @aud_email_verification "email-verification"

  def get_aud(:registration), do: @aud_registration
  def get_aud(:email_verification), do: @aud_email_verification

  def subject_for_token(type, %{"email" => email}) when type in [@aud_registration, @aud_email_verification] do
    {:ok, email}
  end

  def build_claims(claims, @aud_registration, _opts) do
    {:ok, Map.put(claims, "aud", @aud_registration)}
  end

  def build_claims(claims, @aud_email_verification, _opts) do
    {:ok, Map.put(claims, "aud", @aud_email_verification)}
  end

  def build_claims(claims, _resource, _opts), do: {:ok, claims}
end
