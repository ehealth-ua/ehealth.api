defmodule EHealth.Repo.Migrations.ChangeKvedsDictionaries do
  use Ecto.Migration

  def change do
    execute """
    UPDATE dictionaries SET
    name = 'KVEDS_ALLOWED_MSP'
    WHERE name = 'KVEDS_ALLOWED';
    """

    execute """
    INSERT INTO dictionaries
      (name, values, labels, is_active)
      SELECT
        'KVEDS_ALLOWED_PHARMACY',
        '{"47.73": "Роздрібна торгівля фармацевтичними товарами в спеціалізованих магазинах"}',
        '["SYSTEM"]',
        True
      WHERE
      NOT EXISTS (
        SELECT name FROM dictionaries WHERE name = 'KVEDS_ALLOWED_PHARMACY'
      );
    """
  end
end
