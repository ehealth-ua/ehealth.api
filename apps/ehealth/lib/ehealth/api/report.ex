defmodule EHealth.API.Report do
  @moduledoc false

  use EHealth.API.Helpers.MicroserviceBase
  @behaviour EHealth.API.ReportBehaviour

  def get_capitation_list(params, headers \\ []) do
    get("/api/capitation_reports", headers, params: params)
  end

  def get_capitation_details(params, headers \\ []) do
    get("/api/capitation_report_details", headers, params: params)
  end

  def get_declaration_count(ids, headers) do
    post!("/api/parties/declaration_count", Jason.encode!(%{ids: ids}), headers)
  end
end
