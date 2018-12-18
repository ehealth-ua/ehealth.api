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
    test "index", %{conn: conn} do
      patch(conn, dictionary_path(conn, :update, "GENDER"), @gender)
      patch(conn, dictionary_path(conn, :update, "DOCUMENT_TYPE"), @document_type)

      conn = get(conn, dictionary_path(conn, :index))
      resp = json_response(conn, 200)["data"]
      assert Enum.member?(resp, @gender)
      assert Enum.member?(resp, @document_type)
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
