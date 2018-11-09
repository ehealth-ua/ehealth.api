defmodule Core.LegalEntities.Renderer do
  @moduledoc false

  alias Core.LegalEntities.LegalEntity

  def render("show_reimbursement.json", %LegalEntity{} = legal_entity) do
    Map.take(legal_entity, ~w(id name short_name public_name type edrpou status)a)
  end
end
