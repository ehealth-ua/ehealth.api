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
    test "search by name", %{conn: conn} do
      insert(:prm, :substance, name: "Этивон")
      %{id: id} = insert(:prm, :substance, name: "Диэтиламид")

      conn = get conn, substance_path(conn, :index), name: "этила"
      assert [substance] = json_response(conn, 200)["data"]
      assert id == substance["id"]
      assert "Диэтиламид" == substance["name"]
    end

    test "paging", %{conn: conn} do
      for _ <- 1..21, do: insert(:prm, :substance)

      # default entities per page is 10
      conn = get conn, substance_path(conn, :index)
      first_page = json_response(conn, 200)["data"]
      assert 10 == length(first_page)

      # same order for first page
      conn = get conn, substance_path(conn, :index)
      assert first_page == json_response(conn, 200)["data"]

      # second page
      conn = get conn, substance_path(conn, :index), page: 2
      refute first_page == json_response(conn, 200)["data"]

      # page_size
      conn = get conn, substance_path(conn, :index), [page_size: 5, page: 3]
      resp = json_response(conn, 200)
      assert 5 == length(resp["data"])

      page_meta = %{
        "page_number" => 3,
        "page_size" => 5,
        "total_pages" => 5,
        "total_entries" => 21
      }
      assert page_meta == resp["paging"]
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
