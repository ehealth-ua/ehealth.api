defmodule EHealth.Repo.Migrations.RenameNumberToRequestNumberInMrr do
  use Ecto.Migration

  def change do
    rename table(:medication_request_requests), :number, to: :request_number
  end
end
