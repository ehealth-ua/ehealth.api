defmodule Core.Repo.Migrations.AddVerificationCodeToMrr do
  use Ecto.Migration

  def change do
    alter table(:medication_request_requests) do
      add(:verification_code, :string, null: true)
    end
  end
end
