defmodule Core.FraudRepo.Migrations.AddPartiesNameFields do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:parties) do
      add(:first_name, :string)
      add(:last_name, :string)
      add(:second_name, :string)
    end
  end
end
