defmodule Core.PRMRepo.Migrations.AddLegalEntitiesNameIndex do
  @moduledoc false

  use Ecto.Migration

  def change do
    create index("legal_entities", [:name])
  end
end
