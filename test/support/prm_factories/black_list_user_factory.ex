defmodule EHealth.PRMFactories.BlackListUserFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def black_list_user_factory do
        tax_id = sequence("100500")
        insert(:prm, :party, tax_id: tax_id)

        %EHealth.BlackListUsers.BlackListUser{
          tax_id: tax_id,
          is_active: true,
          inserted_by: UUID.generate(),
          updated_by: UUID.generate(),
        }
      end
    end
  end
end
