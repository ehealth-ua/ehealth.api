defmodule EHealth.PRMRepo.Migrations.DropInnms do
  use Ecto.Migration

  def change do
    drop_if_exists(table(:innms))
  end
end
