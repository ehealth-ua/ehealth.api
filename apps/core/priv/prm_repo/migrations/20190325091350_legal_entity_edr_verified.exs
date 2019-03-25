defmodule Core.PRMRepo.Migrations.LegalEntityEdrVerified do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table("legal_entities") do
      add(:edr_verified, :boolean, null: true)
    end
  end
end
