defmodule EHealth.Guardian do
  @moduledoc false

  use Guardian, otp_app: :ehealth

  def subject_for_token(:email, %{"email" => email}) do
    {:ok, email}
  end
end
