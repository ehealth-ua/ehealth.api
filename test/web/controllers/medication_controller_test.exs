defmodule EHealth.Web.MedicationControllerTest do
  use EHealth.Web.ConnCase

  alias EHealth.PRM.Drugs.Medication.Schema, as: Medication
  alias Ecto.UUID

  @create_attrs %{
    name: "some name",
    form: "some form",
    code_atc: "C08CA01",
    certificate: "some certificate",
    certificate_expired_at: "2010-04-17",
    container: container("Pill"),
    manufacturer: build(:manufacturer),
    package_min_qty: 42,
    package_qty: 42,
  }
  @invalid_attrs %{
    certificate: nil,
    certificate_expired_at: nil,
    code_atc: nil,
    container: nil,
    form: nil,
    ingredients: nil,
    manufacturer: nil,
    name: nil,
    package_min_qty: nil,
    package_qty: nil,
    type: nil,
  }

  @doc """
  Creates Medication with type MEDICATION
  """
  def fixture(:medication) do
    insert(:prm, :medication)
  end

  @doc """
  Creates Medication with type INNM
  """
  def fixture(:innm) do
    insert(:prm, :innm)
  end

  describe "index" do
    test "search by name", %{conn: conn} do
      insert(:prm, :innm, name: "Диэтиламид",)
      %{id: medication_id} = insert(:prm, :medication, name: "Диэтиламид",)

      conn = get conn, medication_path(conn, :index), name: "этила"
      assert [medication] = json_response(conn, 200)["data"]
      assert medication_id == medication["id"]
      assert "Диэтиламид" == medication["name"]
    end

    test "search by name and innm_name", %{conn: conn} do
      %{id: innm_id} = insert(:prm, :innm, name: "Диэтиламид")
      %{id: innm_id2} = insert(:prm, :innm, name: "Диэтиламид форте")
      %{id: innm_id3} = insert(:prm, :innm, name: "Диэтиламидон")

      %{id: medication_id} = insert(:prm, :medication, [name: "Полізамін", ingredients: []])
      %{id: medication_id2} = insert(:prm, :medication, name: "Эвказолин")

      insert(:prm, :ingredient_medication, medication_id: medication_id, innm_id: innm_id)
      insert(:prm, :ingredient_medication, medication_id: medication_id, innm_id: innm_id2, is_active_substance: false)

      insert(:prm, :ingredient_medication, medication_id: medication_id2, innm_id: innm_id2)
      insert(:prm, :ingredient_medication, medication_id: medication_id2, innm_id: innm_id3, is_active_substance: false)

      conn = get conn, medication_path(conn, :index), [innm_name: "этила", name: "Полізамін"]

      assert [medication] = json_response(conn, 200)["data"]

      assert medication_id == medication["id"]
      assert "Полізамін" == medication["name"]
      assert 2 == length(medication["ingredients"])

      # assert that id is valid innm_id reference
      Enum.each(medication["ingredients"], fn %{"id" => id} ->
        assert id in [innm_id, innm_id2]
      end)
    end

    test "paging", %{conn: conn} do
      for _ <- 1..21, do: insert(:prm, :medication)

      conn = get conn, medication_path(conn, :index), [page_size: 10, page: 2]
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
    setup [:create_medication]

    test "200 OK", %{conn: conn, medication: %Medication{id: id}} do
      conn = get conn, medication_path(conn, :show, id)
      data = json_response(conn, 200)["data"]
      assert Map.has_key?(data, "is_active")
      # ToDo: check response fields
    end

    test "404 Not Found", %{conn: conn} do
      assert_raise Ecto.NoResultsError, ~r/expected at least one result but got none in query/, fn ->
        conn = get conn, medication_path(conn, :show, UUID.generate())
        json_response(conn, 404)
      end
    end
  end

  describe "create medication" do
    test "renders medication when data is valid", %{conn: conn} do
      ingredient = build(:ingredient, id: fixture(:innm).id)
      ingredient_inactive = build(:ingredient, [id: fixture(:innm).id, is_active_substance: false])

      attrs = Map.put(@create_attrs, :ingredients, [ingredient, ingredient_inactive])

      conn = post conn, medication_path(conn, :create), attrs

      assert %{"id" => id} = json_response(conn, 201)["data"]
      conn = get conn, medication_path(conn, :show, id)
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

    test "ingredients innm duplicated", %{conn: conn} do
      %{id: innm_id} = fixture(:innm)

      ingredient = build(:ingredient, id: innm_id)
      ingredient2 = build(:ingredient, [id: innm_id, is_active_substance: false])

      attrs = Map.put(@create_attrs, :ingredients, [ingredient, ingredient2])

      conn = post conn, medication_path(conn, :create), attrs
      json_response(conn, 422)
    end

    test "substance id in ingredients", %{conn: conn} do
      ingredient = build(:ingredient, id: insert(:prm, :substance).id)

      attrs = Map.put(@create_attrs, :ingredients, [ingredient])

      conn = post conn, medication_path(conn, :create), attrs
      json_response(conn, 422)
    end

    test "medication id in ingredients", %{conn: conn} do
      ingredient = build(:ingredient, id: fixture(:medication).id)

      attrs = Map.put(@create_attrs, :ingredients, [ingredient])

      conn = post conn, medication_path(conn, :create), attrs
      json_response(conn, 422)
    end

    test "is_active_substance duplicated", %{conn: conn} do
      ingredient = build(:ingredient, id: fixture(:innm).id)
      ingredient2 = build(:ingredient, id: fixture(:innm).id)

      attrs = Map.put(@create_attrs, :ingredients, [ingredient, ingredient2])

      conn = post conn, medication_path(conn, :create), attrs
      json_response(conn, 422)
    end

    test "no active substances in ingredients", %{conn: conn} do
      ingredient_inactive = build(:ingredient, [id: fixture(:innm).id, is_active_substance: false])
      ingredient_inactive2 = build(:ingredient, [id: fixture(:innm).id, is_active_substance: false])

      attrs = Map.put(@create_attrs, :ingredients, [ingredient_inactive, ingredient_inactive2])

      conn = post conn, medication_path(conn, :create), attrs
      json_response(conn, 422)
    end

    test "medication with inactive INNM", %{conn: conn} do
      new_innm = insert(:prm, :innm, is_active: false)
      ingredient = build(:ingredient, id: new_innm.id)
      attrs = Map.put(@create_attrs, :ingredients, [ingredient])

      conn = post conn, medication_path(conn, :create), attrs
      json_response(conn, 422)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, medication_path(conn, :create), @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "deactivate medication" do
    setup [:create_medication]

    test "success", %{conn: conn, medication: %Medication{id: id} = medication} do
      conn = patch conn, medication_path(conn, :deactivate, medication)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      refute json_response(conn, 200)["data"]["is_active"]
    end

    test "Medication is inactive", %{conn: conn} do
      medication = insert(:prm, :medication, is_active: false)

      assert_raise Ecto.NoResultsError, ~r/expected at least one result but got none in query/, fn ->
        conn = patch conn, medication_path(conn, :deactivate, medication)
        json_response(conn, 404)
      end
    end
  end

  defp create_medication(_) do
    medication = fixture(:medication)
    {:ok, medication: medication}
  end
end
