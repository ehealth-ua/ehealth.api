defmodule Core.FraudRepo.Migrations.RemoveVerificationCodeFromMedicationRequest do
  use Ecto.Migration

  def change do
    alter table(:medication_requests, primary_key: false) do
      remove(:verification_code)
    end
  end
end
