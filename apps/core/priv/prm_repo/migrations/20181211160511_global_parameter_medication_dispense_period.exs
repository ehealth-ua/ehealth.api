defmodule Core.PRMRepo.Migrations.GlobalParameterMedicationDispensePeriod do
  use Ecto.Migration

  alias Core.GlobalParameters

  def change do
    user_id = Confex.fetch_env!(:core, :system_user)

    GlobalParameters.create(
      %{
        "parameter" => "medication_dispense_period",
        "value" => "30",
        "inserted_by" => user_id,
        "updated_by" => user_id
      },
      user_id
    )
  end
end
