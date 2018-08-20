defmodule Core.PRMRepo.Migrations.FixContractFields do
  @moduledoc false

  use Ecto.Migration

  def change do
    execute(~s(ALTER TABLE contracts ALTER COLUMN "id_form" DROP DEFAULT))
    execute(~s(ALTER TABLE contracts ALTER COLUMN "nhs_signed_date" DROP DEFAULT))
  end
end
