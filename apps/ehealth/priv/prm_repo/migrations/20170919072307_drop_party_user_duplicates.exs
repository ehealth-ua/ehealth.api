defmodule EHealth.PRMRepo.Migrations.DropPartyUserDuplicates do
  use Ecto.Migration

  def change do
    execute("""
    DELETE FROM party_users
    WHERE id IN (
      SELECT id FROM (
        SELECT id, ROW_NUMBER() OVER (partition BY user_id ORDER BY inserted_at desc) AS rnum
        FROM party_users
      ) t
      WHERE t.rnum > 1
    );
    """)
  end
end
