defmodule Core.PRMRepo.Migrations.AddReasonAttrToContracts do
  use Ecto.Migration

  def change do
    alter table(:contracts) do
      add(:reason, :text)
    end
  end
end
