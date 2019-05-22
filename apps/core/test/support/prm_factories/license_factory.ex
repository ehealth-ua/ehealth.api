defmodule Core.PRMFactories.LicenseFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Core.LegalEntities.License
      alias Ecto.UUID

      def license_factory do
        today = Date.utc_today()
        uuid = UUID.generate()

        %License{
          id: UUID.generate(),
          is_active: true,
          license_number: "1234567",
          type: License.type(:msp),
          issued_by: "foo",
          issued_date: today,
          issuer_status: "valid",
          expiry_date: Date.add(today, 365),
          active_from_date: today,
          inserted_by: uuid,
          updated_by: uuid
        }
      end
    end
  end
end
