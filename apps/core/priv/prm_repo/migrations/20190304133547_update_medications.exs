defmodule Core.PRMRepo.Migrations.UpdateMedications do
  @moduledoc false

  use Ecto.Migration

  def change do
    prm_migrations_dir = Application.app_dir(:core, "priv/prm_repo/migrations")

    File.read!(Path.join(prm_migrations_dir, "reimbursement_registry_2019.sql"))
    |> String.split("\n\n\n")
    |> Enum.map(&execute/1)
  end
end
