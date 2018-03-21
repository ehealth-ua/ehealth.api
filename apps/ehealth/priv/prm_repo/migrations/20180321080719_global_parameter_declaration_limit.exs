defmodule EHealth.PRMRepo.Migrations.GlobalParameterDeclarationLimit do
  @moduledoc false

  use Ecto.Migration
  alias EHealth.GlobalParameters.GlobalParameter
  alias EHealth.GlobalParameters

  def change do
    GlobalParameters.create(
      %{"parameter" => "declaration_limit", "value" => "2000"},
      Confex.fetch_env!(:ehealth, :system_user)
    )
  end
end
