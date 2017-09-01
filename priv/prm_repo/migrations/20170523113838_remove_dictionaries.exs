defmodule EHealth.PRMRepo.Migrations.RemoveDictionaries do
  use Ecto.Migration

  def change do
    drop table(:dictionaries)
  end
end
