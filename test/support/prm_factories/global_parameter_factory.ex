defmodule EHealth.PRMFactories.GlobalParameterFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def global_parameter_factory do
        %EHealth.GlobalParameters.GlobalParameter{
          parameter: Base.url_encode64(:crypto.strong_rand_bytes(10)),
          value: :rand.normal(),
          inserted_by: UUID.generate(),
          updated_by: UUID.generate()
        }
      end
    end
  end
end
