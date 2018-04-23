defmodule EHealth.API.Report do
  @moduledoc false

  use HTTPoison.Base
  use Confex, otp_app: :ehealth
  use EHealth.API.Helpers.MicroserviceBase

  @behaviour EHealth.API.ReportBehaviour

  def get_declaration_count(ids, headers) do
    post!("/api/parties/declaration_count", Poison.encode!(%{ids: ids}), headers)
  end
end
