defmodule Core.UaddressesFactories.SettlementFactory do
  @moduledoc false

  alias Ecto.UUID

  defmacro __using__(_) do
    quote do
      def settlement_factory do
        now = DateTime.utc_now()

        %{
          id: UUID.generate(),
          type: "VILLAGE",
          name: "ВИСОКЕ",
          koatuu: "0120455302",
          mountain_group: false,
          region_id: UUID.generate(),
          district_id: UUID.generate(),
          parent_settlement_id: UUID.generate(),
          inserted_at: now,
          updated_at: now
        }
      end
    end
  end
end
