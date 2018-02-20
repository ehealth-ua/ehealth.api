defmodule EHealth.PRMRepo.Migrations.AddPartyInfoFields do
  use Ecto.Migration

  def change do
    alter table(:parties) do
      add(:educations, :jsonb)
      add(:qualifications, :jsonb)
      add(:specialities, :jsonb)
      add(:science_degree, :jsonb)
    end
  end
end
