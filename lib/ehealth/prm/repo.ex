defmodule EHealth.PRMRepo do
  @moduledoc false

  use Ecto.Repo, otp_app: :ehealth
  use Scrivener
  use EctoTrail
end
