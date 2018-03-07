defmodule EHealth.Web.CabinetControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false
  alias Ecto.UUID

  defmodule MpiServer do
    use MicroservicesHelper
    alias EHealth.MockServer

    Plug.Router.patch "/persons/c8912855-21c3-4771-ba18-bcd8e524f14c" do
      response =
        conn.body_params
        |> MockServer.wrap_response()
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end
  end

  defmodule MithrilServer do
    use MicroservicesHelper
    alias EHealth.MockServer

    Plug.Router.get "/admin/users/8069cb5c-3156-410b-9039-a1b2f2a4136c" do
      user = %{
        "id" => "8069cb5c-3156-410b-9039-a1b2f2a4136c",
        "settings" => %{},
        "email" => "test@example.com",
        "type" => "user",
        "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c"
      }

      response =
        user
        |> MockServer.wrap_response()
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/admin/clients/c3cc1def-48b6-4451-be9d-3b777ef06ff9/details" do
      response =
        %{"client_type_name" => "CABINET"}
        |> MockServer.wrap_response()
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/admin/clients/75dfd749-c162-48ce-8a92-428c106d5dc3/details" do
      response =
        %{"client_type_name" => "MSP"}
        |> MockServer.wrap_response()
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/admin/users/668d1541-e4cf-4a95-a25a-60d83864ceaf" do
      user = %{
        "id" => "668d1541-e4cf-4a95-a25a-60d83864ceaf",
        "settings" => %{},
        "email" => "test@example.com",
        "type" => "user"
      }

      response =
        user
        |> MockServer.wrap_response()
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/admin/users/:id" do
      Plug.Conn.send_resp(conn, 404, "")
    end
  end

  setup do
    {:ok, port, ref1} = start_microservices(MpiServer)
    System.put_env("MPI_ENDPOINT", "http://localhost:#{port}")

    {:ok, port, ref2} = start_microservices(MithrilServer)
    System.put_env("OAUTH_ENDPOINT", "http://localhost:#{port}")

    on_exit(fn ->
      System.put_env("MPI_ENDPOINT", "http://localhost:4040")
      System.put_env("OAUTH_ENDPOINT", "http://localhost:4040")
      stop_microservices(ref1)
      stop_microservices(ref2)
    end)

    :ok
  end

  describe "update person" do
    test "no required header", %{conn: conn} do
      conn = patch(conn, cabinet_path(conn, :update_person, UUID.generate()))
      assert resp = json_response(conn, 401)
      assert %{"error" => %{"type" => "access_denied", "message" => "Missing header x-consumer-metadata"}} = resp
    end

    test "invalid params", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: legal_entity.id}))

      conn = patch(conn, cabinet_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"))
      assert resp = json_response(conn, 422)

      assert %{
               "error" => %{
                 "invalid" => [
                   %{
                     "entry" => "$.signed_content"
                   }
                 ]
               }
             } = resp
    end

    test "invalid signed content", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64("invalid")
        })

      assert resp = json_response(conn, 422)
      assert %{"error" => %{"is_valid" => false}} = resp
    end

    test "tax_id doesn't match with signed content", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      party = insert(:prm, :party)
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Poison.encode!(%{}))
        })

      assert resp = json_response(conn, 409)

      assert %{
               "error" => %{
                 "type" => "request_conflict",
                 "message" => "Person that logged in, person that is changed and person that sign should be the same"
               }
             } = resp
    end

    test "tax_id doesn't match with signer", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      party = insert(:prm, :party)
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Poison.encode!(%{"tax_id" => "2222222220"}))
        })

      assert resp = json_response(conn, 409)

      assert %{
               "error" => %{
                 "type" => "request_conflict",
                 "message" => "Person that logged in, person that is changed and person that sign should be the same"
               }
             } = resp
    end

    test "invalid signed content changeset", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      party = insert(:prm, :party, tax_id: "2222222220")
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      conn =
        conn
        |> put_req_header("edrpou", "2222222220")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Poison.encode!(%{"tax_id" => "2222222220"}))
        })

      assert json_response(conn, 422)
    end

    test "user person_id doesn't match query param id", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")

      conn =
        conn
        |> put_req_header("x-consumer-id", "668d1541-e4cf-4a95-a25a-60d83864ceaf")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Poison.encode!(%{}))
        })

      assert json_response(conn, 403)
    end

    test "invalid client_type", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "75dfd749-c162-48ce-8a92-428c106d5dc3")

      conn =
        conn
        |> put_req_header("x-consumer-id", "668d1541-e4cf-4a95-a25a-60d83864ceaf")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: legal_entity.id}))

      conn = patch(conn, cabinet_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{})
      assert json_response(conn, 403)
    end

    test "success update person", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      party = insert(:prm, :party, tax_id: "2222222220")
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      conn =
        conn
        |> put_req_header("edrpou", "2222222220")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" =>
            Base.encode64(
              Poison.encode!(%{
                "first_name" => "Артем",
                "last_name" => "Иванов",
                "birth_date" => "1990-01-01",
                "birth_country" => "Ukraine",
                "birth_settlement" => "Kyiv",
                "gender" => "MALE",
                "documents" => [%{"type" => "PASSPORT", "number" => "120518"}],
                "addresses" => [
                  %{
                    "type" => "RESIDENCE",
                    "zip" => "02090",
                    "settlement_type" => "CITY",
                    "country" => "UA",
                    "settlement" => "KYIV",
                    "area" => "KYIV",
                    "settlement_id" => UUID.generate(),
                    "building" => "15"
                  }
                ],
                "authentication_methods" => [%{"type" => "OFFLINE"}],
                "emergency_contact" => %{
                  "first_name" => "Петро",
                  "last_name" => "Іванов",
                  "second_name" => "Миколайович"
                },
                "process_disclosure_data_consent" => true,
                "secret" => "secret",
                "tax_id" => "2222222220"
              })
            )
        })

      assert json_response(conn, 200)
    end
  end
end
