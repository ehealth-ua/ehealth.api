defmodule Core.EventManagerRepo do
  @moduledoc false

  use Ecto.Repo, otp_app: :core
  use EctoTrail
end
