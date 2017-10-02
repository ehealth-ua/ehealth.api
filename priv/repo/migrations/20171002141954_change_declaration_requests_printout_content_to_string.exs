defmodule EHealth.Repo.Migrations.ChangeDeclarationRequestsPrintoutContentToString do
  use Ecto.Migration

  def change do
    alter table(:declaration_requests) do
      modify :printout_content, :text
    end
  end
end
