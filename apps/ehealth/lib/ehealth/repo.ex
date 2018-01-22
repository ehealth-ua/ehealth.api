defmodule EHealth.Repo do
  @moduledoc false

  use Ecto.Repo, otp_app: :ehealth
  use Scrivener, page_size: 50, max_page_size: 500
end
