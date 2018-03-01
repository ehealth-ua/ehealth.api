defmodule EHealth.PRMRepo.Migrations.AddPartyDeclarationFields do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:parties) do
      add(:declaration_limit, :integer)
    end
  end
end
