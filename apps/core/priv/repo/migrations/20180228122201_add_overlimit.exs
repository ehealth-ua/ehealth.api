defmodule Core.Repo.Migrations.AddOverlimit do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:declaration_requests) do
      add(:overlimit, :boolean)
    end
  end
end
