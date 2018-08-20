defmodule Core.PRMRepo.Migrations.GlobalParameterDeclarationLimit do
  @moduledoc false

  use Ecto.Migration
  alias Core.GlobalParameters.GlobalParameter
  alias Core.GlobalParameters

  def change do
    GlobalParameters.create(
      %{"parameter" => "declaration_limit", "value" => "2000"},
      Confex.fetch_env!(:core, :system_user)
    )
  end
end
