defmodule EHealth.PRM.LegalEntities do
  @moduledoc false

  alias EHealth.PRMRepo
  alias EHealth.PRM.LegalEntities.Schema, as: LegalEntity

  def get_legal_entity_by_id(id) do
    PRMRepo.get(LegalEntity, id)
  end
end
