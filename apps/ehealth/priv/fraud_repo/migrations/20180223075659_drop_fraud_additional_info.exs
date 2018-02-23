defmodule EHealth.FraudRepo.Migrations.DropFraudAdditionalInfo do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:employees) do
      remove(:additional_info)
    end
  end
end
