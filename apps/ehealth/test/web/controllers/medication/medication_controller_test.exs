defmodule EHealth.Web.MedicationControllerTest do
  use EHealth.Web.ConnCase

  alias Core.Medications.Medication
  alias Ecto.UUID

  @create_attrs %{
    name: "some name",
    form: "some form",
    code_atc: ["C08CA01", "C01BD01"],
    certificate: "some certificate",
    certificate_expired_at: "2010-04-17",
    container: container("PILL"),
    manufacturer: build(:manufacturer),
    package_min_qty: 21,
    package_qty: 42,
    daily_dosage: 0.5
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
    daily_dosage: 0
  }

  describe "get drugs" do
    test "valid response", %{conn: conn} do
      fixture(:list)
      conn = get(conn, medication_path(conn, :drugs))
      json_response(conn, 200)["data"]
    end

    test "invalid search params", %{conn: conn} do
      params = [
        [innm_id: 123],
        [innm_name: 123],
        [innm_sctid: 123],
        [innm_dosage_id: 123],
        [innm_dosage_name: 123],
        [innm_dosage_form: 123],
        [medication_code_atc: 123],
        [medical_program_id: 123]
      ]

      Enum.each(params, fn param ->
        conn = get(conn, medication_path(conn, :drugs), param)
        refute [] == json_response(conn, 422)["errors"]
      end)
    end

    test "paging", %{conn: conn} do
      fixture(:list)
      conn = get(conn, medication_path(conn, :drugs), %{"page" => "2", "page_size" => "1"})
      paging = json_response(conn, 200)["paging"]
      assert 1 == paging["page_size"]
      assert 2 == paging["total_entries"]
      assert 2 == paging["total_pages"]
      assert 2 == paging["page_number"]
    end

    test "paging with INNM name", %{conn: conn} do
      fixture(:list)
      %{id: innm_id} = insert(:prm, :innm, name: "Будафинол")
      %{id: dosage_id} = insert(:prm, :innm_dosage, name: "Будафинолон Альтернативний")
      %{id: dosage_id2} = insert(:prm, :innm_dosage, name: "Будафинолон Альтернативний 2")
      %{id: med_id} = insert(:prm, :medication, package_qty: 20, package_min_qty: 40, name: "Будафинолодон")
      %{id: med_id2} = insert(:prm, :medication, package_qty: 20, package_min_qty: 40, name: "Будафинолодон2")
      insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id, innm_child_id: innm_id)
      insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id2, innm_child_id: innm_id)
      insert(:prm, :ingredient_medication, parent_id: med_id, medication_child_id: dosage_id)
      insert(:prm, :ingredient_medication, parent_id: med_id2, medication_child_id: dosage_id2)

      conn = get(conn, medication_path(conn, :drugs), innm_name: "бу")
      resp = json_response(conn, 200)
      assert 3 == length(resp["data"])
      assert 3 == resp["paging"]["total_entries"]
    end

    test "find by INNM name", %{conn: conn} do
      fixture(:list)
      conn = get(conn, medication_path(conn, :drugs), innm_name: "пропі")
      data = json_response(conn, 200)["data"]
      assert 1 == length(data)

      innm_dosage = List.first(data)
      assert 2 == length(innm_dosage["packages"])
      assert "Бупропіон" == innm_dosage["innm"]["name"]
    end

    test "find by INNM id", %{conn: conn} do
      %{innms: [id, _]} = fixture(:list)

      conn = get(conn, medication_path(conn, :drugs), innm_id: id)
      data = json_response(conn, 200)["data"]
      assert 1 == length(data)

      innm_dosage = List.first(data)
      assert 2 == length(innm_dosage["packages"])
      assert id == innm_dosage["innm"]["id"]
    end

    test "find by INNM Dosage id", %{conn: conn} do
      %{innm_dosage: [id, _]} = fixture(:list)

      conn = get(conn, medication_path(conn, :drugs), innm_dosage_id: id)
      data = json_response(conn, 200)["data"]
      assert 1 == length(data)

      innm_dosage = List.first(data)
      assert 2 == length(innm_dosage["packages"])
      assert id == innm_dosage["id"]
    end

    test "find by INNM Dosage id with dublicates", %{conn: conn} do
      id = fixture(:list_with_dublicates)

      conn = get(conn, medication_path(conn, :drugs), innm_dosage_id: id)

      data = json_response(conn, 200)["data"]
      assert 1 == length(data)

      innm_dosage = List.first(data)
      assert 1 == length(innm_dosage["packages"])
      assert id == innm_dosage["id"]
    end

    test "find by Medication code_atc", %{conn: conn} do
      fixture(:list)
      conn = get(conn, medication_path(conn, :drugs), medication_code_atc: "Z00CA01")
      data = json_response(conn, 200)["data"]
      assert 1 == length(data)

      innm_dosage = List.first(data)

      assert [package] = innm_dosage["packages"]
      assert 10 == package["package_qty"]
      assert 40 == package["package_min_qty"]

      assert "Діетіламід" == innm_dosage["innm"]["name"]
      assert "Діетіламід Форте" == innm_dosage["name"]
    end

    test "find by Medication code_atc and medical program id", %{conn: conn} do
      %{medical_program: medical_program_id, innms: innms, innm_dosage: innm_dosage} =
        fixture(:list_with_medication_program)

      [innm_in | innms_out] = innms
      [innm_dosage_in | innm_dosages_out] = innm_dosage

      resp =
        conn
        |> get(medication_path(conn, :drugs), %{
          medication_code_atc: "Z00CA01",
          medical_program_id: medical_program_id
        })
        |> json_response(200)
        |> Map.get("data")

      assert 1 == length(resp)

      resp_innm = resp |> hd() |> get_in(~w(innm id))
      assert innm_in == resp_innm
      Enum.each(innms_out, fn innm_out -> refute innm_out == resp_innm end)

      resp_innm_dosage = resp |> hd() |> Map.get("id")
      assert innm_dosage_in == resp_innm_dosage
      Enum.each(innm_dosages_out, fn innm_dosage_out -> refute innm_dosage_out == resp_innm_dosage end)
    end

    test "find by INNM Dosage name", %{conn: conn} do
      fixture(:list)
      conn = get(conn, medication_path(conn, :drugs), innm_dosage_name: "он Фор")
      data = json_response(conn, 200)["data"]
      assert 1 == length(data), "Get Drugs should return list with on element"

      innm_dosage = List.first(data)
      assert 2 == length(innm_dosage["packages"])
      assert "Бупропіон Форте" == innm_dosage["name"]

      # not primary ingredient
      conn = get(conn, medication_path(conn, :drugs), innm_dosage_name: "он Ла")
      data = json_response(conn, 200)["data"]
      assert 0 == length(data), "Get Drugs should return an empty list"
    end

    test "find by medical program id", %{conn: conn} do
      %{medical_program: medical_program_id, innms: innms, innm_dosage: innm_dosage} =
        fixture(:list_with_medication_program)

      [innm_in | innms_out] = innms
      [innm_dosage_in | innm_dosages_out] = innm_dosage

      resp =
        conn
        |> get(medication_path(conn, :drugs), medical_program_id: medical_program_id)
        |> json_response(200)
        |> Map.get("data")

      assert 1 == length(resp)

      resp_innm = resp |> hd() |> get_in(~w(innm id))
      assert innm_in == resp_innm
      Enum.each(innms_out, fn innm_out -> refute innm_out == resp_innm end)

      resp_innm_dosage = resp |> hd() |> Map.get("id")
      assert innm_dosage_in == resp_innm_dosage
      Enum.each(innm_dosages_out, fn innm_dosage_out -> refute innm_dosage_out == resp_innm_dosage end)
    end
  end

  describe "index" do
    test "search by name", %{conn: conn} do
      %{id: innm_id} = insert(:prm, :innm, name: "Діетіламід")

      innm_dosage = insert(:prm, :innm_dosage, name: "Діетіламід")
      insert(:prm, :ingredient_innm_dosage, innm_child_id: innm_id, parent_id: innm_dosage.id)

      medication = insert(:prm, :medication, name: "Діетіламід")
      insert(:prm, :ingredient_medication, medication_child_id: innm_dosage.id, parent_id: medication.id)

      conn = get(conn, medication_path(conn, :index), name: "етіла")
      assert [resp_medication] = json_response(conn, 200)["data"]
      assert medication.id == resp_medication["id"]
      assert "Діетіламід" == resp_medication["name"]
    end

    test "search by name and innm_dosage_name", %{conn: conn} do
      %{id: dosage_id} = insert(:prm, :innm_dosage, name: "Діетіламід")
      %{id: dosage_id2} = insert(:prm, :innm_dosage, name: "Діетіламід форте")
      %{id: dosage_id3} = insert(:prm, :innm_dosage, name: "Діетіламідон")

      %{id: med_id} = insert(:prm, :medication, name: "Полізамін")
      %{id: med_id2} = insert(:prm, :medication, name: "Бупропіон")

      insert(:prm, :ingredient_medication, parent_id: med_id, medication_child_id: dosage_id)
      insert(:prm, :ingredient_medication, parent_id: med_id, medication_child_id: dosage_id2, is_primary: false)

      insert(:prm, :ingredient_medication, parent_id: med_id2, medication_child_id: dosage_id2)
      insert(:prm, :ingredient_medication, parent_id: med_id2, medication_child_id: dosage_id3, is_primary: false)

      conn = get(conn, medication_path(conn, :index), innm_dosage_name: "етіла", name: "Полізамін")

      assert [medication] = json_response(conn, 200)["data"]

      assert med_id == medication["id"]
      assert "Полізамін" == medication["name"]
      assert 2 == length(medication["ingredients"])

      # assert that id is valid innm_dosage_id reference
      Enum.each(medication["ingredients"], fn %{"id" => id} ->
        assert id in [dosage_id, dosage_id2]
      end)
    end

    test "paging", %{conn: conn} do
      for _ <- 1..21, do: fixture(:medication)

      conn = get(conn, medication_path(conn, :index), page_size: 10, page: 2)
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

    test "200 OK", %{
      conn: conn,
      medication: %Medication{
        id: id
      }
    } do
      conn = get(conn, medication_path(conn, :show, id))
      data = json_response(conn, 200)["data"]
      assert Map.has_key?(data, "is_active")
      # ToDo: check response fields
    end

    test "404 Not Found", %{conn: conn} do
      assert_raise Ecto.NoResultsError, ~r/expected at least one result but got none in query/, fn ->
        conn = get(conn, medication_path(conn, :show, UUID.generate()))
        json_response(conn, 404)
      end
    end
  end

  describe "create medication" do
    test "renders medication when data is valid", %{conn: conn} do
      ingredient = get_ingredient(id: fixture(:innm_dosage).id)
      ingredient_inactive = get_ingredient(id: fixture(:innm_dosage).id, is_primary: false)

      attrs = Map.put(@create_attrs, :ingredients, [ingredient, ingredient_inactive])
      conn = post(conn, medication_path(conn, :create), attrs)

      assert %{"id" => id} = json_response(conn, 201)["data"]
      conn = get(conn, medication_path(conn, :show, id))
      resp_data = json_response(conn, 200)["data"]

      Enum.each(@create_attrs, fn {field, value} ->
        resp_value = resp_data[Atom.to_string(field)]
        assert convert_atom_keys_to_strings(value) == resp_value, "Response field #{field}
            expected: #{inspect(value)},
            passed: #{inspect(resp_value)}"
      end)
    end

    test "invalid code_atc", %{conn: conn} do
      ingredient = get_ingredient(id: fixture(:innm_dosage).id)
      ingredient_inactive = get_ingredient(id: fixture(:innm_dosage).id, is_primary: false)

      attrs =
        @create_attrs
        |> Map.put(:code_atc, ["C08CA01", "М01АЕ01"])
        |> Map.put(:ingredients, [ingredient, ingredient_inactive])

      conn = post(conn, medication_path(conn, :create), attrs)

      resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.code_atc.[1]",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" =>
                         "string does not match pattern \"^[abcdghjlmnprsvABCDGHJLMNPRSV]{1}[0-9]{2}[a-zA-Z]{2}[0-9]{2}$\"",
                       "rule" => "format"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "empty code_atc", %{conn: conn} do
      ingredient = get_ingredient(id: fixture(:innm_dosage).id)
      ingredient_inactive = get_ingredient(id: fixture(:innm_dosage).id, is_primary: false)

      attrs =
        @create_attrs
        |> Map.put(:code_atc, [])
        |> Map.put(:ingredients, [ingredient, ingredient_inactive])

      conn = post(conn, medication_path(conn, :create), attrs)

      resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.code_atc",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "expected a minimum of 1 items but got 0",
                       "params" => %{"min" => 1},
                       "rule" => "length"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "duplicated code_atc", %{conn: conn} do
      ingredient = get_ingredient(id: fixture(:innm_dosage).id)
      ingredient_inactive = get_ingredient(id: fixture(:innm_dosage).id, is_primary: false)

      attrs =
        @create_attrs
        |> Map.put(:code_atc, ["C08CA01", "C08CA02", "C08CA02"])
        |> Map.put(:ingredients, [ingredient, ingredient_inactive])

      conn = post(conn, medication_path(conn, :create), attrs)

      resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.code_atc",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "atc codes are duplicated",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "ingredients innm_dosage duplicated", %{conn: conn} do
      %{id: innm_dosage_id} = fixture(:innm_dosage)

      ingredient = get_ingredient(id: innm_dosage_id)
      ingredient2 = get_ingredient(id: innm_dosage_id, is_primary: false)

      attrs = Map.put(@create_attrs, :ingredients, [ingredient, ingredient2])

      conn = post(conn, medication_path(conn, :create), attrs)
      json_response(conn, 422)
    end

    test "innm id in ingredients", %{conn: conn} do
      ingredient = get_ingredient(id: insert(:prm, :innm).id)

      attrs = Map.put(@create_attrs, :ingredients, [ingredient])

      conn = post(conn, medication_path(conn, :create), attrs)
      json_response(conn, 422)
    end

    test "medication id in ingredients", %{conn: conn} do
      ingredient = get_ingredient(id: fixture(:medication).id)

      attrs = Map.put(@create_attrs, :ingredients, [ingredient])

      conn = post(conn, medication_path(conn, :create), attrs)
      json_response(conn, 422)
    end

    test "invalid package quantity", %{conn: conn} do
      ingredient = get_ingredient(id: fixture(:innm_dosage).id)
      attrs = Map.merge(@create_attrs, %{ingredients: [ingredient], package_min_qty: 13})

      conn = post(conn, medication_path(conn, :create), attrs)
      json_response(conn, 422)
    end

    test "invalid numrator type", %{conn: conn} do
      ingredient = get_ingredient(id: insert(:prm, :innm_dosage).id)
      attrs = Map.merge(@create_attrs, %{ingredients: [ingredient], container: container("Nebuliser suspension")})

      conn = post(conn, medication_path(conn, :create), attrs)
      json_response(conn, 422)
    end

    test "is_primary duplicated", %{conn: conn} do
      ingredient = get_ingredient(id: fixture(:innm_dosage).id)
      ingredient2 = get_ingredient(id: fixture(:innm_dosage).id)

      attrs = Map.put(@create_attrs, :ingredients, [ingredient, ingredient2])

      conn = post(conn, medication_path(conn, :create), attrs)
      json_response(conn, 422)
    end

    test "no active innms in ingredients", %{conn: conn} do
      ingredient_inactive = get_ingredient(id: fixture(:innm_dosage).id, is_primary: false)
      ingredient_inactive2 = get_ingredient(id: fixture(:innm_dosage).id, is_primary: false)

      attrs = Map.put(@create_attrs, :ingredients, [ingredient_inactive, ingredient_inactive2])

      conn = post(conn, medication_path(conn, :create), attrs)
      json_response(conn, 422)
    end

    test "medication with inactive INNMDosage", %{conn: conn} do
      new_innm_dosage = insert(:prm, :innm_dosage, is_active: false)
      ingredient = get_ingredient(id: new_innm_dosage.id)
      attrs = Map.put(@create_attrs, :ingredients, [ingredient])

      conn = post(conn, medication_path(conn, :create), attrs)
      json_response(conn, 422)
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, medication_path(conn, :create), @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "deactivate medication" do
    setup [:create_medication]

    test "success", %{conn: conn, medication: %Medication{id: id} = medication} do
      conn = patch(conn, medication_path(conn, :deactivate, medication))
      resp = json_response(conn, 200)["data"]
      assert %{"id" => ^id} = resp
      refute resp["is_active"]
      assert is_list(resp["code_atc"])
    end

    test "Medication is inactive", %{conn: conn} do
      medication = insert(:prm, :medication, is_active: false)

      conn = patch(conn, medication_path(conn, :deactivate, medication))
      refute json_response(conn, 200)["data"]["is_active"]
    end

    test "Medication is participant of active Program Medication", %{conn: conn} do
      medication = insert(:prm, :medication)
      insert(:prm, :program_medication, medication_id: medication.id)

      conn = patch(conn, medication_path(conn, :deactivate, medication))
      err_msg = "Medication is participant of an active Medical Program"
      assert err_msg == json_response(conn, 409)["error"]["message"]
    end
  end

  defp create_medication(_) do
    medication = fixture(:medication)
    {:ok, medication: medication}
  end

  @doc """
  Creates Medication
  """
  def fixture(:medication) do
    %{id: innm_dosage_id} = fixture(:innm_dosage)
    medication = insert(:prm, :medication)
    insert(:prm, :ingredient_medication, medication_child_id: innm_dosage_id, parent_id: medication.id)
    medication
  end

  @doc """
  Creates INNMDosage
  """
  def fixture(:innm_dosage) do
    %{id: innm_id} = insert(:prm, :innm)
    innm_dosage = insert(:prm, :innm_dosage)
    insert(:prm, :ingredient_innm_dosage, innm_child_id: innm_id, parent_id: innm_dosage.id)

    innm_dosage
  end

  @doc """
  Creates related INNM, INNMDosage and Medications
  """
  def fixture(:list) do
    %{id: innm_id1} = insert(:prm, :innm, name: "Бупропіон")
    %{id: innm_id2} = insert(:prm, :innm, name: "Діетіламід")
    %{id: innm_id3} = insert(:prm, :innm, name: "Фіз. розчин")
    %{id: innm_id4} = insert(:prm, :innm, name: "Неактивний")

    %{id: dosage_id1} = insert(:prm, :innm_dosage, name: "Бупропіон Форте")
    %{id: dosage_id2} = insert(:prm, :innm_dosage, name: "Бупропіон Лайт")
    %{id: dosage_id3} = insert(:prm, :innm_dosage, name: "Діетіламід Форте")
    %{id: dosage_id4} = insert(:prm, :innm_dosage, name: "Діетіламід Лайт")
    %{id: dosage_id5} = insert(:prm, :innm_dosage, name: "Неактивний Лайт")

    insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id1, innm_child_id: innm_id1)
    insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id1, innm_child_id: innm_id3, is_primary: false)

    insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id2, innm_child_id: innm_id1)
    insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id2, innm_child_id: innm_id3, is_primary: false)

    insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id3, innm_child_id: innm_id2)
    insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id3, innm_child_id: innm_id3, is_primary: false)

    insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id4, innm_child_id: innm_id2)
    insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id4, innm_child_id: innm_id3, is_primary: false)

    insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id5, innm_child_id: innm_id4)

    %{id: med_id1} = insert(:prm, :medication, package_qty: 5, package_min_qty: 20, name: "Бупропіонол")
    %{id: med_id2} = insert(:prm, :medication, package_qty: 10, package_min_qty: 20, name: "Діетіламідон")
    %{id: med_id3} = insert(:prm, :medication, package_qty: 10, package_min_qty: 30, name: "Бупропіон Діетіламід")

    %{id: med_id4} =
      insert(
        :prm,
        :medication,
        name: "Діетіламід Бупропіон",
        package_qty: 10,
        package_min_qty: 40,
        code_atc: ["Z00CA01", "Z00CA02"]
      )

    %{id: med_id5} = insert(:prm, :medication, name: "Неактивний мед")

    insert(:prm, :ingredient_medication, parent_id: med_id1, medication_child_id: dosage_id1)
    insert(:prm, :ingredient_medication, parent_id: med_id1, medication_child_id: dosage_id2, is_primary: false)

    insert(:prm, :ingredient_medication, parent_id: med_id2, medication_child_id: dosage_id3)
    insert(:prm, :ingredient_medication, parent_id: med_id2, medication_child_id: dosage_id4, is_primary: false)

    insert(:prm, :ingredient_medication, parent_id: med_id3, medication_child_id: dosage_id1)
    insert(:prm, :ingredient_medication, parent_id: med_id3, medication_child_id: dosage_id4, is_primary: false)

    insert(:prm, :ingredient_medication, parent_id: med_id4, medication_child_id: dosage_id3)
    insert(:prm, :ingredient_medication, parent_id: med_id4, medication_child_id: dosage_id2, is_primary: false)

    insert(:prm, :ingredient_medication, parent_id: med_id5, medication_child_id: dosage_id5, is_primary: false)

    %{innms: [innm_id1, innm_id2], innm_dosage: [dosage_id1, dosage_id2]}
  end

  def fixture(:list_with_dublicates) do
    %{id: innm_id} = insert(:prm, :innm, name: "Бупропіон")
    %{id: dosage_id} = insert(:prm, :innm_dosage, name: "Бупропіон Форте")
    insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id, innm_child_id: innm_id)
    insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id, innm_child_id: innm_id, is_primary: false)
    %{id: med_id} = insert(:prm, :medication, package_qty: 5, package_min_qty: 20, name: "Бупропіонол")
    insert(:prm, :ingredient_medication, parent_id: med_id, medication_child_id: dosage_id)
    insert(:prm, :ingredient_medication, parent_id: med_id, medication_child_id: dosage_id)

    dosage_id
  end

  def fixture(:list_with_medication_program) do
    %{id: innm_id} = insert(:prm, :innm, name: "Бупропіон")
    %{id: innm_id_out} = insert(:prm, :innm, name: "Діетіламід")

    %{id: dosage_id} = insert(:prm, :innm_dosage, name: "Бупропіон Форте")
    %{id: dosage_id_out_1} = insert(:prm, :innm_dosage, name: "Діетіламід Форте")
    %{id: dosage_id_out_2} = insert(:prm, :innm_dosage, name: "Діетіламід Лайт")

    insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id, innm_child_id: innm_id)
    insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id, innm_child_id: innm_id, is_primary: false)
    insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id_out_1, innm_child_id: innm_id_out)
    insert(:prm, :ingredient_innm_dosage, parent_id: dosage_id_out_1, innm_child_id: innm_id_out, is_primary: false)

    %{id: med_id} =
      insert(:prm, :medication,
        package_qty: 5,
        package_min_qty: 20,
        name: "Бупропіонол",
        code_atc: ["Z00CA01", "Z00CA02"]
      )

    %{id: med_id_out} = insert(:prm, :medication, package_qty: 10, package_min_qty: 20, name: "Діетіламідон")

    insert(:prm, :ingredient_medication, parent_id: med_id, medication_child_id: dosage_id)
    insert(:prm, :ingredient_medication, parent_id: med_id, medication_child_id: dosage_id)
    insert(:prm, :ingredient_medication, parent_id: med_id_out, medication_child_id: dosage_id_out_1)
    insert(:prm, :ingredient_medication, parent_id: med_id_out, medication_child_id: dosage_id_out_2, is_primary: false)

    %{medical_program_id: medical_program_id} = insert(:prm, :program_medication, medication_id: med_id)
    insert(:prm, :program_medication, medication_id: med_id_out)

    %{
      medical_program: medical_program_id,
      innms: [innm_id, innm_id_out],
      innm_dosage: [dosage_id, dosage_id_out_1, dosage_id_out_2]
    }
  end

  defp get_ingredient(params) do
    :ingredient_medication
    |> build(params)
    |> Map.take(~w(id is_primary dosage)a)
  end
end
