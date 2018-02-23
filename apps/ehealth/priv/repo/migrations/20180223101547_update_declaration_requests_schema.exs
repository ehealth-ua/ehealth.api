defmodule EHealth.Repo.Migrations.UpdateDeclarationRequestsSchema do
  @moduledoc false

  use Ecto.Migration

  def change do
    alter table(:declaration_requests) do
      modify(:data, :map, null: true)
      modify(:authentication_method_current, :jsonb, null: true)
      modify(:printout_content, :text, null: true)
    end
  end
end
