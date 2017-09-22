defmodule EHealth.Web.MedicationControllerTest do
  use EHealth.Web.ConnCase

  alias EHealth.PRM.Medication
  alias Ecto.UUID

  @ingredient %{
    "is_active_substance" => true,
    "dosage" => %{
      "numerator_unit" => "mg",
      "numerator_value" => 10,
      "denumerator_unit" => "g",
      "denumerator_value" => 1
    }
  }
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
    %{id: medication_id} = fixture(:innm)
    ingredient = build(:ingredient, id: medication_id)

    insert(:prm, :medication, ingredients: [ingredient])
  end

  @doc """
  Creates Medication with type Substance
  """
  def fixture(:innm) do
    %{id: substance_id} = insert(:prm, :substance)
    ingredient = build(:ingredient, id: substance_id)

    insert(:prm, :innm, ingredients: [ingredient])
  end

  describe "index" do
    test "search by name", %{conn: conn} do
      %{id: substance_id} = insert(:prm, :substance)
      innm_data = [
        name: "Диэтиламид",
        ingredients: [build(:ingredient, id: substance_id)]
      ]
      %{id: innm_id} = insert(:prm, :innm, innm_data)

      medication_data = [
        name: "Диэтиламид",
        ingredients: [build(:ingredient, id: innm_id)]
      ]
      %{id: medication_id} = insert(:prm, :medication, medication_data)

      conn = get conn, medication_path(conn, :index), name: "этила"
      assert [medication] = json_response(conn, 200)["data"]
      assert medication_id == medication["id"]
      assert "Диэтиламид" == medication["name"]
    end

    test "paging", %{conn: conn} do
      %{id: medication_id} = fixture(:innm)
      ingredient = build(:ingredient, id: medication_id)
      for _ <- 1..21, do: insert(:prm, :medication, ingredients: [ingredient])

      conn = get conn, medication_path(conn, :index), page: 2
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
      _data = json_response(conn, 200)["data"]
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
      new_medication = fixture(:medication)
      ingredient = Map.put(@ingredient, "id", new_medication.id)
      ingredient_inactive = Map.merge(@ingredient, %{"id" => new_medication.id, "is_active_substance" => false})
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

    test "is_active_substance duplicated", %{conn: conn} do
      new_medication = fixture(:medication)
      ingredient = Map.put(@ingredient, "id", new_medication.id)
      attrs = Map.put(@create_attrs, :ingredients, [ingredient, ingredient])

      conn = post conn, medication_path(conn, :create), attrs
      json_response(conn, 422)
    end

    test "no active substances", %{conn: conn} do
      new_medication = fixture(:medication)
      ingredient_inactive = Map.merge(@ingredient, %{"id" => new_medication.id, "is_active_substance" => false})
      attrs = Map.put(@create_attrs, :ingredients, [ingredient_inactive, ingredient_inactive])

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

      assert_raise Ecto.NoResultsError, ~r/expected at least one result but got none in query/, fn ->
        conn = get conn, medication_path(conn, :show, id)
        json_response(conn, 404)
      end
    end

    test "Medication is inactive", %{conn: conn} do
      %{id: medication_id} = fixture(:innm)
      ingredient = build(:ingredient, id: medication_id)
      medication = insert(:prm, :medication, ingredients: [ingredient], is_active: false)

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
