defmodule EHealth.Web.INNMDosageControllerTest do
  use EHealth.Web.ConnCase

  alias EHealth.Medications.INNMDosage
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

  describe "index" do
    test "search by name", %{conn: conn} do
      %{id: id} = insert(:prm, :innm_dosage, [name: "Сульфід натрію"])

      conn = get conn, innm_dosage_path(conn, :index), name: "фід на"
      assert [innm_dosage] = json_response(conn, 200)["data"]
      assert id == innm_dosage["id"]
      assert "Сульфід натрію" == innm_dosage["name"]
    end

    test "paging", %{conn: conn} do
      for _ <- 1..21, do: insert(:prm, :innm_dosage)

      conn = get conn, innm_dosage_path(conn, :index), [page_size: 10, page: 2]
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

    test "200 OK", %{conn: conn, innm_dosage: %INNMDosage{id: id}} do
      conn = get conn, innm_dosage_path(conn, :show, id)
      data = json_response(conn, 200)["data"]
      assert Map.has_key?(data, "is_active")
      # ToDo: check response fields
    end

    test "404 Not Found", %{conn: conn} do
      assert_raise Ecto.NoResultsError, ~r/expected at least one result but got none in query/, fn ->
        conn = get conn, innm_dosage_path(conn, :show, UUID.generate())
        json_response(conn, 404)
      end
    end
  end

  describe "create INNMDosage" do
    test "renders INNMDosage when data is valid", %{conn: conn} do
      %{id: innm_id} = insert(:prm, :innm)
      ingredient =
        :ingredient_medication
        |> build(id: innm_id)
        |> Map.take(~w(id is_primary dosage)a)
      attrs = Map.put(@create_attrs, :ingredients, [ingredient])

      conn = post conn, innm_dosage_path(conn, :create), attrs

      assert %{"id" => id} = json_response(conn, 201)["data"]
      conn = get conn, innm_dosage_path(conn, :show, id)
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
      conn = post conn, innm_dosage_path(conn, :create), @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "deactivate INNMDosage" do
    setup [:create_innm]

    test "success", %{conn: conn, innm_dosage: %INNMDosage{id: id} = innm_dosage} do
      conn = patch conn, innm_dosage_path(conn, :deactivate, innm_dosage)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get conn, innm_dosage_path(conn, :show, id)
      refute json_response(conn, 200)["data"]["is_active"]
    end

    test "INNMDosage is inactive", %{conn: conn} do
      innm_dosage = insert(:prm, :innm_dosage, is_active: false)

      conn = patch conn, innm_dosage_path(conn, :deactivate, innm_dosage)
      refute json_response(conn, 200)["data"]["is_active"]
    end

    test "Medication is active", %{conn: conn} do
      innm_dosage = insert(:prm, :innm_dosage)
      med = insert(:prm, :medication)
      insert(:prm, :ingredient_medication, parent_id: med.id, medication_child_id: innm_dosage.id)

      conn = patch conn, innm_dosage_path(conn, :deactivate, innm_dosage)
      json_response(conn, 409)
    end
  end

  def fixture(:innm_dosage) do
    %{id: innm_id} = insert(:prm, :innm)
    innm_dosage = insert(:prm, :innm_dosage)
    insert(:prm, :ingredient_innm_dosage, [innm_child_id: innm_id, parent_id: innm_dosage.id])

    innm_dosage
  end

  defp create_innm(_) do
    innm_dosage = fixture(:innm_dosage)
    {:ok, innm_dosage: innm_dosage}
  end
end
