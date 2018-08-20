defmodule Core.Repo.Migrations.AddNhsSignedDate do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:contract_requests) do
      add(:nhs_signed_date, :date)
    end
  end
end
