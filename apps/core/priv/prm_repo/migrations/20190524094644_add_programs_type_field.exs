defmodule Core.PRMRepo.Migrations.AddProgramsTypeField do
  use Ecto.Migration

  def change do
    alter table(:medical_programs) do
      add(:type, :text)
    end

    execute("UPDATE medical_programs SET type = 'MEDICATION'")

    alter table(:medical_programs) do
      modify(:type, :text, null: false)
    end
  end
end
