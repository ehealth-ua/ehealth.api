defmodule EHealth.PRMRepo.Migrations.SetPartiesDeclarationLimit do
  use Ecto.Migration

  def change do
    execute("UPDATE parties SET declaration_limit = 2000;")
  end
end
