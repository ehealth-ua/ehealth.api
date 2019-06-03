defmodule Core.PRMFactories.ServiceFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Core.Services.Service
      alias Core.Services.ServiceGroup
      alias Core.Services.ServicesGroups
      alias Core.Services.ProgramService
      alias Ecto.UUID

      def service_factory do
        %Service{
          code: "FJ",
          name: "Ультразвукові дослідження",
          is_active: true,
          request_allowed: false,
          inserted_by: UUID.generate(),
          updated_by: UUID.generate()
        }
      end

      def service_group_factory do
        %ServiceGroup{
          name: "Ультразвукові дослідження в гастроентерології",
          code: "2FJ",
          is_active: true,
          request_allowed: false,
          inserted_by: UUID.generate(),
          updated_by: UUID.generate()
        }
      end

      def services_groups_factory do
        %ServicesGroups{
          inserted_by: UUID.generate(),
          updated_by: UUID.generate()
        }
      end

      def program_service_factory do
        %ProgramService{
          description: "Доступний сервіс в кожен дім - це реальність",
          consumer_price: 199.99,
          is_active: true,
          request_allowed: true,
          medical_program: build(:medical_program),
          inserted_by: UUID.generate(),
          updated_by: UUID.generate()
        }
      end
    end
  end
end
