defmodule Core.ILFactories.RegisterFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def register_factory do
        uuid = Ecto.UUID.generate()

        %Core.Registers.Register{
          qty: %{
            total: 0,
            errors: 0,
            not_found: 0,
            processing: 0
          },
          file_name: "Some name",
          type: Core.Registers.Register.type(:death),
          status: Core.Registers.Register.status(:new),
          inserted_by: uuid,
          updated_by: uuid
        }
      end

      def register_entry_factory do
        uuid = Ecto.UUID.generate()

        %Core.Registers.RegisterEntry{
          status: Core.Registers.Register.status(:new),
          document_type: "TAX_ID",
          document_number: sequence("222222222"),
          inserted_by: uuid,
          updated_by: uuid,
          register: insert(:il, :register),
          person_id: Ecto.UUID.generate()
        }
      end
    end
  end
end
