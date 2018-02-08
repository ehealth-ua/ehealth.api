defmodule EHealth.ILFactories.RegisterFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def register_factory do
        uuid = Ecto.UUID.generate()

        %EHealth.Registers.Register{
          qty: %{
            total: 0,
            errors: 0,
            not_found: 0,
            processing: 0
          },
          file_name: "Some name",
          type: EHealth.Registers.Register.type(:death),
          status: EHealth.Registers.Register.status(:new),
          inserted_by: uuid,
          updated_by: uuid
        }
      end

      def register_entry_factory do
        uuid = Ecto.UUID.generate()

        %EHealth.Registers.RegisterEntry{
          status: EHealth.Registers.Register.status(:new),
          tax_id: sequence("222222222"),
          national_id: sequence("national_id"),
          passport: sequence("passport"),
          birth_certificate: sequence("birth_certificate"),
          temporary_certificate: sequence("temporary_certificate"),
          status: EHealth.Registers.RegisterEntry.status(:matched),
          inserted_by: uuid,
          updated_by: uuid,
          register: insert(:il, :register)
        }
      end
    end
  end
end
