defmodule EHealth.Web.ServiceControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  describe "get services" do
    test "success get services", %{conn: conn} do
      group1 = insert(:prm, :service_group, code: "G1")
      group2 = insert(:prm, :service_group, code: "G2")
      group3 = insert(:prm, :service_group, parent_id: group1.id, code: "G3")
      group4 = insert(:prm, :service_group, parent_id: group2.id, code: "G4")
      group5 = insert(:prm, :service_group, parent_id: group3.id, code: "G5")
      group6 = insert(:prm, :service_group, parent_id: group2.id, code: "G6")
      service1 = insert(:prm, :service)
      service2 = insert(:prm, :service)
      insert(:prm, :services_groups, service: service1, service_group: group5, alias: "УЗД1")
      insert(:prm, :services_groups, service: service2, service_group: group5)
      insert(:prm, :services_groups, service: service1, service_group: group4, alias: "УЗД2")
      insert(:prm, :services_groups, service: service1, service_group: group6, alias: "УЗД3")

      conn = get(conn, service_path(conn, :index))
      data = json_response(conn, 200)["data"]
      assert Enum.map(data, &Map.get(&1, "id")) -- [group1.id, group2.id] == []
      group1_response = Enum.find(data, fn v -> v["id"] == group1.id end)
      assert group1_response |> Map.get("groups") |> hd() |> Map.get("id") == group3.id
      assert group1_response |> Map.get("groups") |> hd() |> Map.get("groups") |> hd() |> Map.get("id") == group5.id

      services =
        group1_response
        |> Map.get("groups")
        |> hd()
        |> Map.get("groups")
        |> hd()
        |> Map.get("services")

      assert Enum.map(services, &Map.get(&1, "id")) -- [service1.id, service2.id] == []
      assert Enum.map(services, &Map.get(&1, "name")) -- ["УЗД1", service2.name] == []
    end
  end
end
