defmodule EHealth.PRMRepo do
  @moduledoc false

  use Ecto.Repo, otp_app: :ehealth
  use Scrivener, max_page_size: 500
  use EctoTrail
end
