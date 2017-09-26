defmodule EHealth.Web.INNMControllerTest do
  use EHealth.Web.ConnCase

  alias EHealth.PRM.Drugs.INNM.Schema, as: INNM
  alias Ecto.UUID

  @create_attrs %{
    name: "some name",
    form: "some form",
  }
  @invalid_attrs %{
    type: "MEDICATION",
    name: "some name",
    form: "some form",
  }

  @doc """
  Creates Medication with type Substance
  """
  def fixture(:innm) do
    insert(:prm, :innm)
  end

  describe "index" do
    test "search by name", %{conn: conn} do
      %{id: id} = insert(:prm, :innm, [name: "Сульфід натрію"])

      conn = get conn, innm_path(conn, :index), name: "фід на"
      assert [innm] = json_response(conn, 200)["data"]
      assert id == innm["id"]
      assert "Сульфід натрію" == innm["name"]
    end

    test "paging", %{conn: conn} do
      for _ <- 1..21, do: insert(:prm, :innm)

      conn = get conn, innm_path(conn, :index), page: 2
      resp = json_response(conn, 200)
      assert 10 == length(resp["data"])

      page_meta = %{
        "page_number" => 2,
        "page_size" => 10,
        "total_pages" => 3,
        "total_entries" => 21
      }
      assert page_meta == resp["paging"]
    end

  end

  describe "show" do
    setup [:create_innm]

    test "200 OK", %{conn: conn, innm: %INNM{id: id}} do
      conn = get conn, innm_path(conn, :show, id)
      data = json_response(conn, 200)["data"]
      assert Map.has_key?(data, "is_active")
      # ToDo: check response fields
    end

    test "404 Not Found", %{conn: conn} do
      assert_raise Ecto.NoResultsError, ~r/expected at least one result but got none in query/, fn ->
        conn = get conn, innm_path(conn, :show, UUID.generate())
        json_response(conn, 404)
      end
    end
  end

  describe "create INNM" do
    test "renders INNM when data is valid", %{conn: conn} do
      %{id: substance_id} = insert(:prm, :substance)
      ingredient = build(:ingredient, id: substance_id)
      attrs = Map.put(@create_attrs, :ingredients, [ingredient])

      conn = post conn, innm_path(conn, :create), attrs

      assert %{"id" => id} = json_response(conn, 201)["data"]
      conn = get conn, innm_path(conn, :show, id)
      resp_data = json_response(conn, 200)["data"]

      Enum.each(
        @create_attrs,
        fn ({field, value}) ->
          resp_value = resp_data[Atom.to_string(field)]
          assert convert_atom_keys_to_strings(value) == resp_value, "Response field #{field}
            expected: #{inspect value},
            passed: #{inspect resp_value}"
        end
      )
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, innm_path(conn, :create), @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "deactivate INNM" do
    setup [:create_innm]

    test "success", %{conn: conn, innm: %INNM{id: id} = innm} do
      conn = patch conn, innm_path(conn, :deactivate, innm)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, innm_path(conn, :show, id)
      refute json_response(conn, 200)["data"]["is_active"]
    end

    test "INNM is inactive", %{conn: conn} do
      innm = insert(:prm, :innm, is_active: false)

      assert_raise Ecto.NoResultsError, ~r/expected at least one result but got none in query/, fn ->
        conn = patch conn, innm_path(conn, :deactivate, innm)
        json_response(conn, 404)
      end
    end
  end

  defp create_innm(_) do
    innm = fixture(:innm)
    {:ok, innm: innm}
  end
end
