defmodule EHealth.PRMRepo.Migrations.AddContractsParentIdFormId do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:contracts) do
      add(:parent_contract_id, :uuid)
      add(:id_form, :string, null: false, default: "PMD_1")
      add(:nhs_signed_date, :date, null: false)
    end
  end
end
