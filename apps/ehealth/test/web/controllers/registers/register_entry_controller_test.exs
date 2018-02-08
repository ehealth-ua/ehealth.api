defmodule EHealth.Web.RegisterEntryControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  alias EHealth.Registers.RegisterEntry

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
      %{id: id} = insert(:il, :register_entry, tax_id: "234")

      assert [data] =
               conn
               |> get(register_entry_path(conn, :index), tax_id: "234")
               |> json_response(200)
               |> Map.get("data")

      assert id == data["id"]
      assert "234" == data["tax_id"]
    end

    test "search by register_id and birth_certificate", %{conn: conn} do
      %{id: id, register: register} = insert(:il, :register_entry, birth_certificate: "DOO123/123")

      assert [data] =
               conn
               |> get(register_entry_path(conn, :index), birth_certificate: "DOO123/123", register_id: register.id)
               |> json_response(200)
               |> Map.get("data")

      assert id == data["id"]
      assert "DOO123/123" == data["birth_certificate"]
      assert register.id == data["register_id"]
    end

    test "search by inserted_at range", %{conn: conn} do
      insert(:il, :register_entry, status: @matched, inserted_at: ~N[2017-12-12 12:10:12])
      %{id: id} = insert(:il, :register_entry, status: @matched, inserted_at: ~N[2017-12-13 02:10:12])
      insert(:il, :register_entry, status: @matched, inserted_at: ~N[2017-12-14 14:10:12])

      params = %{
        status: @matched,
        inserted_at_from: "2017-12-13",
        inserted_at_to: "2017-12-14"
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
