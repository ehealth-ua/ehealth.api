defmodule EHealth.Repo.Migrations.AddNewDivisionTypes do
  use Ecto.Migration

  def change do
    execute """
    UPDATE dictionaries SET
    values = jsonb_set(jsonb_set(values, '{DRUGSTORE_POINT}', '"Аптечний пункт"'), '{DRUGSTORE}', '"Аптека"')
    WHERE name = 'DIVISION_TYPE';
    """
  end
end
