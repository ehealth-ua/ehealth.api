defmodule Core.PRMRepo.Migrations.EdrDataEdrIdIndex do
  @moduledoc false

  use Ecto.Migration

  def change do
    create(index(:edr_data, [:edr_id], unique: true))
  end
end
