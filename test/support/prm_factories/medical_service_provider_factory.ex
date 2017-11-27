defmodule EHealth.PRMFactories.MedicalServiceProviderFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def medical_service_provider_factory do
        %EHealth.LegalEntities.MedicalServiceProvider{
          licenses: [%{
            license_number: "fd123443",
            issued_by: "Кваліфікацйна комісія",
            issued_date: "2017-02-28",
            expiry_date: "2017-02-28",
            active_from_date: "2017-02-28",
            what_licensed: "реалізація наркотичних засобів",
            order_no: "K-123"
          }],
          accreditation: %{
            category: "some",
            order_date: "some",
            expiry_date: "some",
            issued_date: "some",
            order_no: "some"
          }
        }
      end
    end
  end
end
