defmodule EHealth.Repo.Migrations.RenameRegisterField do
  @moduledoc false

  use Ecto.Migration

  def change do
    rename(table("registers"), :person_type, to: :entity_type)
  end
end
