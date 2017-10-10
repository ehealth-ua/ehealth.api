defmodule EHealth.Web.MedicationRequestController do
  @moduledoc false
  use EHealth.Web, :controller

  alias EHealth.MedicationRequests.API
  alias Scrivener.Page

  action_fallback EHealth.Web.FallbackController

  def index(%Plug.Conn{req_headers: headers} = conn, params) do
    with {:ok, data, paging} <- API.list(params, headers) do
      paging = Enum.map(paging, fn({key, value}) -> {String.to_atom(key), value} end)
      render(conn, "index.json", medication_requests: data, paging: struct(Page, paging))
    end
  end
end
