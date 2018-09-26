defmodule Core.Factories.AddressFactory do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def address_factory do
        %{
          "type" => "RESIDENCE",
          "country" => "UA",
          "area" => "М.КИЇВ",
          "region" => "Бердичівський",
          "settlement" => "Київ",
          "settlement_type" => "CITY",
          "settlement_id" => "adaa4abf-f530-461c-bcbf-a0ac210d955b",
          "street_type" => "STREET",
          "street" => "вул. Ніжинська",
          "building" => "15",
          "apartment" => "23",
          "zip" => "02090"
        }
      end
    end
  end
end
