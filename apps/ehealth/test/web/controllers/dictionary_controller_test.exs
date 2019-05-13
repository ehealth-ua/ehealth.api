defmodule EHealth.Web.DictionaryControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: true

  @gender %{
    "name" => "GENDER",
    "values" => %{
      "MALE" => "Чоловік",
      "FEMALE" => "Жінка"
    },
    "labels" => ["SYSTEM"],
    "is_active" => true
  }

  @document_type %{
    "name" => "DOCUMENT_TYPE",
    "values" => %{
      "PASSPORT" => "Паспорт",
      "NATIONAL_ID" => "Біометричний паспорт",
      "BIRTH_CERTIFICATE" => "Свідоцтво про народження",
      "TEMPORARY_CERTIFICATE" => "Тимчасовий паспорт"
    },
    "labels" => ["SYSTEM", "EXTERNAL"],
    "is_active" => true
  }

  @invalid_attrs %{
    is_active: nil,
    id: 123,
    label: "string",
    values: 9090
  }

  describe "lists" do
    setup context do
      on_exit(fn -> Application.put_env(:core, Core.Dictionaries, big_dictionaries: []) end)
      Application.put_env(:core, Core.Dictionaries, big_dictionaries: ["BIG_ONE", "NEXT_BIG_ONE"])

      insert(:il, :dictionary, name: "SIMPLE_ONE", values: %{})
      insert(:il, :dictionary, name: "BIG_ONE", values: %{})
      insert(:il, :dictionary, name: "NEXT_BIG_ONE", values: %{}, is_active: false)

      context
    end

    test "index", %{conn: conn} do
      patch(conn, dictionary_path(conn, :update, "GENDER"), @gender)
      patch(conn, dictionary_path(conn, :update, "DOCUMENT_TYPE"), @document_type)

      conn = get(conn, dictionary_path(conn, :index))
      resp = json_response(conn, 200)["data"]
      assert Enum.member?(resp, @gender)
      assert Enum.member?(resp, @document_type)
    end

    test "success: not resolving big dictionaries", %{conn: conn} do
      resp_data =
        conn
        |> get(dictionary_path(conn, :index))
        |> json_response(200)
        |> Map.get("data")

      names = Enum.map(resp_data, & &1["name"])

      assert "SIMPLE_ONE" in names
      refute "NEXT_BIG_ONE" in names
      refute "BIG_ONE" in names
    end

    test "success to find big dictionary by name", %{conn: conn} do
      resp_data =
        conn
        |> get(dictionary_path(conn, :index), %{name: "BIG_ONE"})
        |> json_response(200)
        |> Map.get("data")

      assert [%{"name" => "BIG_ONE"}] = resp_data
    end

    test "success to find dictionaries by names and activeness", %{conn: conn} do
      resp_data =
        conn
        |> get(dictionary_path(conn, :index), %{name: "SIMPLE_ONE,BIG_ONE,NEXT_BIG_ONE", is_active: true})
        |> json_response(200)
        |> Map.get("data")

      names = Enum.map(resp_data, & &1["name"])

      assert 2 == length(resp_data)
      assert "SIMPLE_ONE" in names
      assert "BIG_ONE" in names
    end
  end

  describe "update dictionary" do
    test "updates chosen dictionary and renders dictionary when data is valid", %{conn: conn} do
      assert @gender ==
               conn
               |> create_dictionary(@gender)
               |> json_response(200)
               |> Map.fetch!("data")

      update = %{
        "name" => "invalid",
        "values" => %{
          "MALE" => "MAN",
          "FEMALE" => "WOMAN"
        },
        "labels" => ["SYSTEM", "EXTERNAL"],
        "is_active" => true
      }

      assert resp_data =
               conn
               |> patch(dictionary_path(conn, :update, "GENDER"), update)
               |> json_response(200)
               |> Map.get("data")

      assert Map.put(update, "name", "GENDER") == resp_data
    end

    test "fails to update chosen dictionary and renders errors when data is invalid", %{conn: conn} do
      assert resp =
               conn
               |> patch(dictionary_path(conn, :update, "GENDER"), @invalid_attrs)
               |> json_response(422)

      assert %{} != resp["errors"]
    end

    test "fails to update inactive dictionary", %{conn: conn} do
      %{name: name} = insert(:il, :dictionary, is_active: false)

      resp =
        conn
        |> patch(dictionary_path(conn, :update, name), %{"labels" => ["EXTERNAL", "READ_ONLY"]})
        |> json_response(422)

      assert %{"error" => %{"invalid" => [error]}} = resp
      assert "$.is_active" == error["entry"]
    end

    test "fails to deactivate dictionary", %{conn: conn} do
      %{name: name} = insert(:il, :dictionary, is_active: true)

      resp =
        conn
        |> patch(dictionary_path(conn, :update, name), %{"is_active" => false})
        |> json_response(422)

      assert %{"error" => %{"invalid" => [error]}} = resp
      error_description = hd(error["rules"])["description"]

      assert "$.is_active" == error["entry"]
      assert String.contains?(error_description, "deactivate")
    end
  end

  defp create_dictionary(conn, %{"name" => name} = data) do
    patch(conn, dictionary_path(conn, :update, name), data)
  end
end
