defmodule EHealth.Web.INNMControllerTest do
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
      insert(:prm, :innm, name: "Этивон")
      %{id: id} = insert(:prm, :innm, name: "Диэтиламид")

      resp =
        conn
        |> get(innm_path(conn, :index), name: "этила")
        |> json_response(200)
        |> Map.get("data")
        |> assert_list_response_schema("innm")

      assert [innm] = resp
      assert id == innm["id"]
      assert "Диэтиламид" == innm["name"]
    end

    test "search invalid id", %{conn: conn} do
      conn = get conn, innm_path(conn, :index), id: 1000
      json_response(conn, 422)
    end

    test "not active innm in list", %{conn: conn} do
      insert(:prm, :innm, is_active: false)

      conn = get conn, innm_path(conn, :index)
      assert 1 == length(json_response(conn, 200)["data"])
    end

    test "paging", %{conn: conn} do
      for _ <- 1..21, do: insert(:prm, :innm)

      # default entities per page is 50
      conn = get conn, innm_path(conn, :index)
      first_page = json_response(conn, 200)["data"]
      assert 21 == length(first_page)

      # same order for first page
      conn = get conn, innm_path(conn, :index)
      assert first_page == json_response(conn, 200)["data"]

      # second page
      conn = get conn, innm_path(conn, :index), page: 2
      refute first_page == json_response(conn, 200)["data"]

      # page_size
      conn = get conn, innm_path(conn, :index), [page_size: 5, page: 3]
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

  describe "create innm" do
    test "renders innm when data is valid", %{conn: conn} do
      conn = post conn, innm_path(conn, :create), @create_attrs
      assert %{"id" => id} = json_response(conn, 201)["data"]

      data =
        conn
        |> get(innm_path(conn, :show, id))
        |> json_response(200)
        |> Map.get("data")
        |> assert_show_response_schema("innm")

      Enum.each(@create_attrs, fn {field, value} ->
        assert value == Map.get(data, to_string(field))
      end)
    end

    test "duplicate name", %{conn: conn} do
      conn_c = post conn, innm_path(conn, :create), @create_attrs
      json_response(conn_c, 201)["data"]

      conn = post conn, innm_path(conn, :create), @create_attrs
      json_response(conn, 422)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, innm_path(conn, :create), @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "get innm by id" do
    test "not active innm render 200", %{conn: conn} do
      %{id: id} = insert(:prm, :innm, is_active: false)
      conn = get conn, innm_path(conn, :show, id)
      json_response(conn, 200)
    end
  end
end
