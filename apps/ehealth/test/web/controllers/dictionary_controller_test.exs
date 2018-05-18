defmodule EHealth.Web.DictionaryControllerTest do
  use EHealth.Web.ConnCase

  @gender %{
    "name" => "GENDER",
    "values" => %{
      "MALE" => "Чоловік",
      "FEMALE" => "Жінка"
    },
    "labels" => ["SYSTEM"],
    "is_active" => false
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

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  test "lists all entries on index", %{conn: conn} do
    patch(conn, dictionary_path(conn, :update, "GENDER"), Jason.encode!(@gender))
    patch(conn, dictionary_path(conn, :update, "DOCUMENT_TYPE"), Jason.encode!(@document_type))

    conn = get(conn, dictionary_path(conn, :index))
    resp = json_response(conn, 200)["data"]
    assert Enum.member?(resp, @gender)
    assert Enum.member?(resp, @document_type)
  end

  test "updates chosen dictionary and renders dictionary when data is valid", %{conn: conn} do
    assert @gender == conn |> create_dictionary(@gender) |> json_response(200) |> Map.fetch!("data")

    update = %{
      "name" => "invalid",
      "values" => %{
        "MALE" => "MAN",
        "FEMALE" => "WOMAN"
      },
      "labels" => ["SYSTEM", "EXTERNAL"],
      "is_active" => false
    }

    conn = patch(conn, dictionary_path(conn, :update, "GENDER"), update)
    assert json_response(conn, 200)["data"] == Map.put(update, "name", "GENDER")
  end

  test "does not update chosen dictionary and renders errors when data is invalid", %{conn: conn} do
    conn = patch(conn, dictionary_path(conn, :update, "GENDER"), Jason.encode!(@invalid_attrs))
    assert json_response(conn, 422)["errors"] != %{}
  end

  defp create_dictionary(conn, %{"name" => name} = data) do
    patch(conn, dictionary_path(conn, :update, name), data)
  end
end
