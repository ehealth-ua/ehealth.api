defmodule Core.PRMRepo.Migrations.AddContractsParentIdFormId do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:contracts) do
      add(:parent_contract_id, :uuid)
      add(:id_form, :string, null: false, default: "PMD_1")
      add(:nhs_signed_date, :date, null: false, default: fragment("now()::date"))
    end
  end
end
