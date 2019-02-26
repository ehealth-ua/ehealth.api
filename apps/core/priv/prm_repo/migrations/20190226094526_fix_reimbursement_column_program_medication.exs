defmodule Core.PRMRepo.Migrations.FixReimbursementColumnProgramMedication do
  use Ecto.Migration

  def change do
    execute("""
      UPDATE program_medications
      SET reimbursement = concat('{"type": "FIXED", "reimbursement_amount":', round(subquery.price::numeric, 2), '}')::jsonb
      FROM (SELECT id, reimbursement->>'reimbursement_amount' AS price FROM program_medications) AS subquery
      WHERE program_medications.id = subquery.id;
    """)
  end
end
