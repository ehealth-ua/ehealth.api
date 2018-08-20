defmodule Core.FraudRepo.Migrations.NullableAuthMethod do
  @moduledoc false

  use Ecto.Migration

  def change do
    execute("ALTER TABLE declaration_requests ALTER COLUMN authentication_method_current DROP NOT NULL;")
  end
end
