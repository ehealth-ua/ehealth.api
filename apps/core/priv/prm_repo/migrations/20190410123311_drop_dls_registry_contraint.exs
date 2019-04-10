defmodule Core.PRMRepo.Migrations.DropDlsRegistryContraint do
  @moduledoc false

  use Ecto.Migration

  def change do
    drop(constraint(:dls_registry, "dls_registry_division_id_fkey"))
  end
end
