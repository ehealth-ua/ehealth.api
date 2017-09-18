defmodule EHealth.Web.SubstanceControllerTest do
  use EHealth.Web.ConnCase

  @create_attrs %{
    sctid: "10050090",
    name: "Эликсирион Экстра",
    name_original: "Elixirium",
  }

  @invalid_attrs %{
    sctid: "some sctid",
    inserted_by: nil,
    name: nil
  }

  describe "index" do
    test "lists all substances", %{conn: conn} do
      conn = get conn, substance_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create substance" do
    test "renders substance when data is valid", %{conn: conn} do
      conn_c = post conn, substance_path(conn, :create), @create_attrs
      assert %{"id" => id} = json_response(conn_c, 201)["data"]

      conn = get conn, substance_path(conn, :show, id)
      data = json_response(conn, 200)["data"]
      Enum.each(@create_attrs, fn {field, value} ->
        assert value == Map.get(data, to_string(field))
      end)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, substance_path(conn, :create), @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end
end
