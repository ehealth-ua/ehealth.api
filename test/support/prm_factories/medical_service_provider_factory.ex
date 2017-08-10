defmodule EHealth.PRMFactories.MedicalServiceProviderFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def medical_service_provider_factory do
        %EHealth.PRM.MedicalServiceProviders.Schema{
          licenses: [],
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
