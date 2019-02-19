defmodule Core.UaddressesFactories.RegionFactory do
  @moduledoc false

  alias Ecto.UUID

  defmacro __using__(_) do
    quote do
      def region_factory do
        now = DateTime.utc_now()

        %{
          id: UUID.generate(),
          name: "АВТОНОМНА РЕСПУБЛІКА КРИМ",
          koatuu: "0100000000",
          inserted_at: now,
          updated_at: now
        }
      end
    end
  end
end
