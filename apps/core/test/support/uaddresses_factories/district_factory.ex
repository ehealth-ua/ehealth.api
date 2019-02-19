defmodule Core.UaddressesFactories.DistrictFactory do
  @moduledoc false

  alias Ecto.UUID

  defmacro __using__(_) do
    quote do
      def district_factory do
        now = DateTime.utc_now()

        %{
          id: UUID.generate(),
          name: "БАХЧИСАРАЙСЬКИЙ",
          koatuu: "0120400000",
          region_id: UUID.generate(),
          inserted_at: now,
          updated_at: now
        }
      end
    end
  end
end
