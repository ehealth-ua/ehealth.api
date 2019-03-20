defmodule Core.FraudRepo.Migrations.AddMergedPersons do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:merged_pairs, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:master_person_id, :uuid)
      add(:merge_person_id, :uuid)
      timestamps(type: :utc_datetime)
    end
  end
end
