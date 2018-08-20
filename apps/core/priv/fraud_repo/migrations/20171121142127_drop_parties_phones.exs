defmodule Core.FraudRepo.Migrations.DropPartiesPhones do
  use Ecto.Migration

  def change do
    execute("DROP TRIGGER IF EXISTS on_party_insert ON parties;")
    execute("DROP TRIGGER IF EXISTS on_party_update ON parties;")
    execute("DROP FUNCTION IF EXISTS set_party_documents_phones();")

    alter table(:parties) do
      remove(:phones)
      remove(:mobile_phone)
      remove(:land_line_phone)
    end
  end
end
