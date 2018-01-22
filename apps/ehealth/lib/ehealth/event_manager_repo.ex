defmodule EHealth.EventManagerRepo do
  @moduledoc false

  use Ecto.Repo, otp_app: :ehealth
  use EctoTrail
end
