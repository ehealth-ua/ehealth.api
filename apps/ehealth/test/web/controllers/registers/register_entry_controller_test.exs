defmodule EHealth.Web.RegisterEntryControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  alias Core.Registers.RegisterEntry

  @matched RegisterEntry.status(:matched)

  describe "list registers" do
    setup %{conn: conn} do
      insert(:il, :register_entry)
      insert(:il, :register_entry)
      insert(:il, :register_entry)

      %{conn: conn}
    end

    test "success list", %{conn: conn} do
      insert(:prm, :party_user)

      assert 3 =
               conn
               |> get(register_entry_path(conn, :index))
               |> json_response(200)
               |> Map.get("data")
               |> length()
    end

    test "search by tax_id", %{conn: conn} do
      register = insert(:il, :register, type: "reg_type", file_name: "valid.test.csv")
      %{id: id} = insert(:il, :register_entry, document_number: "234", register: register)

      assert [data] =
               conn
               |> get(register_entry_path(conn, :index), document_number: "234")
               |> json_response(200)
               |> Map.get("data")

      assert id == data["id"]
      assert "TAX_ID" == data["document_type"]
      assert "234" == data["document_number"]
      assert register.type == data["type"]
      assert register.file_name == data["file_name"]
    end

    test "search by register_id, document_type and document_number", %{conn: conn} do
      %{id: id, register: register} =
        insert(:il, :register_entry, document_type: "birth_certificate", document_number: "DOO123/123")

      search_attrs = %{
        document_type: "birth_certificate",
        document_number: "DOO123/123",
        register_id: register.id
      }

      assert [data] =
               conn
               |> get(register_entry_path(conn, :index), search_attrs)
               |> json_response(200)
               |> Map.get("data")

      assert id == data["id"]
      assert "DOO123/123" == data["document_number"]
      assert "birth_certificate" == data["document_type"]
      assert register.id == data["register_id"]
    end

    test "search by inserted_at range", %{conn: conn} do
      insert(:il, :register_entry,
        status: @matched,
        inserted_at: %{DateTime.utc_now() | year: 2017, month: 12, day: 12}
      )

      %{id: id} =
        insert(:il, :register_entry,
          status: @matched,
          inserted_at: %{DateTime.utc_now() | year: 2017, month: 12, day: 13}
        )

      insert(:il, :register_entry,
        status: @matched,
        inserted_at: %{DateTime.utc_now() | year: 2017, month: 12, day: 14}
      )

      params = %{
        status: @matched,
        inserted_at_from: "2017-12-13",
        inserted_at_to: "2017-12-13"
      }

      assert [register] =
               conn
               |> get(register_entry_path(conn, :index), params)
               |> json_response(200)
               |> Map.get("data")

      assert id == register["id"]
      assert @matched == register["status"]
    end
  end
end
