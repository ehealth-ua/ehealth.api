defmodule EHealth.Web.LegalEntityController do
  @moduledoc """
  Sample controller for generated application.
  """
  use EHealth.Web, :controller

  alias EHealth.LegalEntity.API

  action_fallback EHealth.Web.FallbackController

  def create_or_update(%Plug.Conn{req_headers: req_headers} = conn, legal_entity_params) do
    with {:ok, legal_entity} <- API.create_legal_entity(legal_entity_params, req_headers) do
      render(conn, "show.json", legal_entity: legal_entity)
    end
  end

end
