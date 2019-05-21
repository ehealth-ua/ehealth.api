defmodule Core.PRMRepo.Migrations.DropLegalEntityEdrpouIndex do
  @moduledoc false

  use Ecto.Migration

  def change do
    drop(index("legal_entities", [:edrpou]))
  end
end
