defmodule EHealth.Web.EUaddressesControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Mox

  alias Ecto.UUID

  setup :verify_on_exit!

  describe "update settlement mountain group" do
    test "success", %{conn: conn} do
      division = insert(:prm, :division)
      settlement_id = Map.get(List.first(division.addresses), :settlement_id)
      data = %{"settlement" => %{"mountain_group" => true}}

      {get_settlement_response, settlement} = get_settlement(settlement_id, 200)

      expect(UAddressesMock, :get_settlement_by_id, fn _id, _headers ->
        get_settlement_response
      end)

      expect(UAddressesMock, :update_settlement, fn _id, data, _headers ->
        update_settlement(settlement, 200, data)
      end)

      conn = patch(conn, uaddresses_path(conn, :update_settlements, settlement_id), data)
      assert json_response(conn, 200)["data"]["mountain_group"]
    end

    test "failed to update divisions", %{conn: conn} do
      division = insert(:prm, :division)
      data = %{"settlement" => %{"mountain_group" => "invalid"}}

      {get_settlement_response, settlement} = get_settlement(division.id, 200)

      expect(UAddressesMock, :get_settlement_by_id, fn _id, _headers ->
        get_settlement_response
      end)

      expect(UAddressesMock, :update_settlement, fn _id, data, _headers ->
        update_settlement(settlement, 200, data)
      end)

      conn = patch(conn, uaddresses_path(conn, :update_settlements, division.id), data)
      assert 422 == json_response(conn, 422)["meta"]["code"]
    end

    test "settlement not set", %{conn: conn} do
      division = insert(:prm, :division)
      data = %{"mountain_group" => "invalid"}

      conn = patch(conn, uaddresses_path(conn, :update_settlements, division.id), data)
      assert 422 == json_response(conn, 422)["meta"]["code"]
    end

    test "no changes", %{conn: conn} do
      division = insert(:prm, :division)

      settlement_id =
        Map.get(
          List.first(division.addresses),
          :settlement_id
        )

      data = %{"settlement" => %{"name" => "Київ"}}

      {get_settlement_response, settlement} = get_settlement(settlement_id, 200)

      expect(UAddressesMock, :get_settlement_by_id, fn _id, _headers ->
        get_settlement_response
      end)

      expect(UAddressesMock, :update_settlement, fn _id, data, _headers ->
        update_settlement(settlement, 200, data)
      end)

      conn = patch(conn, uaddresses_path(conn, :update_settlements, settlement_id), data)
      assert [] != json_response(conn, 200)["meta"]["data"]
    end
  end

  defp get_settlement(id, response_status, mountain_group \\ false) do
    settlement = %{
      "id" => id,
      "region_id" => UUID.generate(),
      "district_id" => UUID.generate(),
      "name" => "Київ",
      "mountain_group" => mountain_group
    }

    {{:ok, %{"data" => settlement, "meta" => %{"code" => response_status}}}, settlement}
  end

  defp update_settlement(settlement, response_status, update_data) do
    update_data =
      if Map.has_key?(update_data, "settlement") do
        Map.get(update_data, "settlement")
      else
        update_data
      end

    settlement = Map.merge(settlement, update_data)

    {:ok, %{"data" => settlement, "meta" => %{"code" => response_status}}}
  end
end
