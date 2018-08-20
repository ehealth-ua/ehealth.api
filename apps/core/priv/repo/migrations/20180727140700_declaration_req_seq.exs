defmodule Core.Repo.Migrations.AddDeclarationRequestSeq do
  use Ecto.Migration

  def up do
    execute("""
    CREATE SEQUENCE IF NOT EXISTS declaration_request START 1000000;
    """)
  end

  def down do
    execute("""
    DROP SEQUENCE IF EXISTS declaration_request;
    """)
  end
end
