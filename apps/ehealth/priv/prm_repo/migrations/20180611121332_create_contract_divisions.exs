defmodule EHealth.PRMRepo.Migrations.CreateContractDivisions do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table(:contract_divisions, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:division_id, :uuid, null: false)
      add(:contract_id, references(:contracts, type: :uuid, on_delete: :nothing))
      add(:inserted_by, :uuid, null: false)
      add(:updated_by, :uuid, null: false)

      timestamps()
    end
  end
end
