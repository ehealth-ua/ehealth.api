defmodule Core.PRMRepo.Migrations.LegalEntityEdrDataReference do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:legal_entities) do
      add(:edr_data_id, references(:edr_data, type: :uuid, on_delete: :nothing))
    end
  end
end
