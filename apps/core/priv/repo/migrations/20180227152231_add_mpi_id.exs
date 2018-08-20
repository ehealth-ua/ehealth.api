defmodule Core.Repo.Migrations.AddMpiId do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:declaration_requests) do
      add(:mpi_id, :uuid)
    end
  end
end
