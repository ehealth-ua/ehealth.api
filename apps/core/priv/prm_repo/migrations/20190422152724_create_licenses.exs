defmodule Core.PRMRepo.Migrations.CreateLicenses do
  @moduledoc false

  use Ecto.Migration

  def change do
    create table("licenses", primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:is_active, :boolean)
      add(:license_number, :string)
      add(:type, :string)
      add(:issued_by, :string)
      add(:issued_date, :date)
      add(:issuer_status, :string)
      add(:expiry_date, :date)
      add(:active_from_date, :date)
      add(:what_licensed, :text)
      add(:order_no, :string)
      add(:inserted_by, :uuid)
      add(:updated_by, :uuid)

      timestamps(type: :utc_datetime)
    end
  end
end
