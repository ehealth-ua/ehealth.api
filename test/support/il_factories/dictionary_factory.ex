defmodule EHealth.ILFactories.DictionaryFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      alias Ecto.UUID

      def dictionary_factory do
        %EHealth.Dictionaries.Dictionary{
          name: sequence("DICTIONARY-"),
          labels: ["SYSTEM"],
          values: %{
            "MOBILE" => "mobile",
            "LANDLINE" => "landline",
          },
          is_active: true,
        }
      end

      def dictionary_phone_type_factory do
        build(:dictionary, [
          name: "PHONE_TYPE",
          values: %{
            "MOBILE" => "mobile",
            "LANDLINE" => "landline",
          }
        ])
      end

      def dictionary_employee_type_factory do
        build(:dictionary, [
          name: "EMPLOYEE_TYPE",
          values: %{"DOCTOR" => "doctor"}
        ])
      end
    end
  end
end
