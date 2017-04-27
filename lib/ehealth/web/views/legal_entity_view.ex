defmodule EHealth.Web.LegalEntityView do
  @moduledoc """
  Sample view for LegalEntitys controller.
  """
  use EHealth.Web, :view
  alias EHealth.Web.LegalEntityView

  def render("index.json", %{legal_entities: legal_entities}) do
    render_many(legal_entities, LegalEntityView, "legal_entity.json")
  end

  def render("show.json", %{legal_entity: legal_entity}) do
    render_one(legal_entity, LegalEntityView, "legal_entity.json")
  end

  def render("legal_entity.json", %{legal_entity: legal_entity}) do
    legal_entity
  end
end
