defmodule Core.FraudRepo.Migrations.AddMergeCandidates do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:merge_candidates, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:person_id, references(:persons, type: :uuid), null: false)
      add(:master_person_id, references(:persons, type: :uuid), null: false)
      add(:status, :string, null: false)
      add(:config, :map)
      add(:details, :map)
      add(:score, :float)

      timestamps(type: :utc_datetime)
    end
  end
end
