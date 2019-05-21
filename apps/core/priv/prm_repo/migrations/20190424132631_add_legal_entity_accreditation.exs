defmodule Core.PRMRepo.Migrations.AddLegalEntityAccreditation do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table("legal_entities") do
      add(:accreditation, :map, null: true)
    end
  end
end
