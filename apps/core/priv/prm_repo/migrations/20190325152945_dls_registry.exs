defmodule Core.PRMRepo.Migrations.DlsRegistry do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("dls_registry", primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:dls_id, :string)
      add(:dls_status, :string)
      add(:division_id, references("divisions", type: :uuid))

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end
  end
end
