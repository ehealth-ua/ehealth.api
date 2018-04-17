defmodule EHealth.Web.Cabinet.PersonsControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false
  import Mox

  alias Ecto.UUID

  defmodule OpsServer do
    @moduledoc false

    use MicroservicesHelper
    alias EHealth.MockServer

    Plug.Router.get "/declarations/0cd6a6f0-9a71-4aa7-819d-6c158201a282" do
      response =
        build(
          :declaration,
          id: "0cd6a6f0-9a71-4aa7-819d-6c158201a282",
          person_id: "c8912855-21c3-4771-ba18-bcd8e524f14c",
          division_id: "21f22e09-8dd9-4ca4-bcc7-72994ef2850a",
          employee_id: "5753a279-8f8c-42b9-8f4d-57b38cabe55d",
          legal_entity_id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9"
        )
        |> MockServer.wrap_response()
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.patch "/declarations/0cd6a6f0-9a71-4aa7-819d-6c158201a282/actions/terminate" do
      response =
        build(
          :declaration,
          person_id: "c8912855-21c3-4771-ba18-bcd8e524f14c",
          id: "0cd6a6f0-9a71-4aa7-819d-6c158201a282",
          status: "terminated"
        )
        |> Map.put("reason", "manual_person")
        |> MockServer.wrap_response()
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/latest_block" do
      response =
        %{"hash" => "some_current_hash"}
        |> MockServer.wrap_response()
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end
  end

  defmodule MpiServer do
    @moduledoc false

    use MicroservicesHelper
    alias EHealth.MockServer

    Plug.Router.patch "/persons/c8912855-21c3-4771-ba18-bcd8e524f14c" do
      response =
        conn.body_params
        |> MockServer.wrap_response()
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/persons/c8912855-21c3-4771-ba18-bcd8e524f14c" do
      birth_date =
        Date.utc_today()
        |> Date.add(-365 * 10)
        |> to_string

      response =
        "c8912855-21c3-4771-ba18-bcd8e524f14c"
        |> MockServer.get_person()
        |> Map.put("first_name", "Алекс")
        |> Map.put("last_name", "Джонс")
        |> Map.put("second_name", "Петрович")
        |> Map.put("addresses", [
          %{
            "zip" => "02090",
            "type" => "REGISTRATION",
            "street_type" => "STREET",
            "street" => "Ніжинська",
            "settlement_type" => "CITY",
            "settlement_id" => "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
            "settlement" => "СОРОКИ-ЛЬВІВСЬКІ",
            "region" => "ПУСТОМИТІВСЬКИЙ",
            "country" => "UA",
            "building" => "15",
            "area" => "ЛЬВІВСЬКА",
            "apartment" => "23"
          },
          %{
            "zip" => "02090",
            "type" => "RESIDENCE",
            "street_type" => "STREET",
            "street" => "Ніжинська",
            "settlement_type" => "CITY",
            "settlement_id" => "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
            "settlement" => "СОРОКИ-ЛЬВІВСЬКІ",
            "region" => "ПУСТОМИТІВСЬКИЙ",
            "country" => "UA",
            "building" => "15",
            "area" => "ЛЬВІВСЬКА",
            "apartment" => "23"
          }
        ])
        |> Map.put("tax_id", "2222222225")
        |> Map.put("birth_date", birth_date)
        |> Map.put("documents", [
          %{"type" => "BIRTH_CERTIFICATE", "number" => "1234567890"}
        ])
        |> Map.put("authentication_methods", [%{"type" => "NA"}])
        |> MockServer.wrap_response()
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/persons" do
      paging = %{
        "page_number" => 1,
        "total_pages" => 1,
        "page_size" => 10,
        "total_entries" => 1
      }

      birth_date =
        Date.utc_today()
        |> Date.add(-365 * 10)
        |> to_string

      person =
        "c8912855-21c3-4771-ba18-bcd8e524f14c"
        |> MockServer.get_person()
        |> Map.put("addresses", [
          %{"type" => "REGISTRATION"},
          %{"type" => "RESIDENCE"}
        ])
        |> Map.put("tax_id", "2222222225")
        |> Map.put("birth_date", birth_date)
        |> Map.put("documents", [
          %{"type" => "BIRTH_CERTIFICATE", "number" => "1234567890"}
        ])
        |> Map.put("authentication_methods", [%{"type" => "NA"}])

      response =
        [person]
        |> MockServer.wrap_response_with_paging(paging)
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end
  end

  defmodule MediaStorageServer do
    @moduledoc false

    use MicroservicesHelper
    alias EHealth.MockServer

    Plug.Router.post "/media_content_storage_secrets" do
      response =
        %{
          secret_url: "http://localhost:4040/good_upload"
        }
        |> MockServer.wrap_response()
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end
  end

  defmodule MithrilServer do
    @moduledoc false

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

    Plug.Router.get "/admin/roles" do
      response =
        [
          %{
            id: "e945360c-8c4a-4f37-a259-320d2533cfc4",
            role_name: "DOCTOR"
          }
        ]
        |> MockServer.wrap_response()
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/admin/users/8069cb5c-3156-410b-9039-a1b2f2a4136c/roles" do
      response =
        [
          %{
            id: UUID.generate(),
            user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c",
            role_id: "e945360c-8c4a-4f37-a259-320d2533cfc4",
            role_name: "DOCTOR"
          }
        ]
        |> MockServer.wrap_response()
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end

    Plug.Router.get "/admin/users/:id" do
      Plug.Conn.send_resp(conn, 404, "")
    end
  end

  defmodule OTPVerificationServer do
    @moduledoc false

    use MicroservicesHelper
    alias EHealth.MockServer

    Plug.Router.get "/verifications/+380955947998" do
      response =
        %{}
        |> MockServer.wrap_response()
        |> Poison.encode!()

      Plug.Conn.send_resp(conn, 200, response)
    end
  end

  # todo: move declarations tests to declaration_controller_test.exs
  setup do
    insert(:prm, :global_parameter, %{parameter: "adult_age", value: "18"})
    insert(:prm, :global_parameter, %{parameter: "declaration_term", value: "40"})
    insert(:prm, :global_parameter, %{parameter: "declaration_term_unit", value: "YEARS"})

    register_mircoservices_for_tests([
      {MpiServer, "MPI_ENDPOINT"},
      {MithrilServer, "OAUTH_ENDPOINT"},
      {OTPVerificationServer, "OTP_VERIFICATION_ENDPOINT"},
      {MediaStorageServer, "MEDIA_STORAGE_ENDPOINT"},
      {OpsServer, "OPS_ENDPOINT"}
    ])

    :ok
  end

  describe "update person" do
    test "no required header", %{conn: conn} do
      conn = patch(conn, cabinet_persons_path(conn, :update_person, UUID.generate()))
      assert resp = json_response(conn, 401)
      assert %{"error" => %{"type" => "access_denied", "message" => "Missing header x-consumer-metadata"}} = resp
    end

    test "invalid params", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: legal_entity.id}))

      conn = patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"))
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
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
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
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
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
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
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
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
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
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
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

      conn = patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{})
      assert json_response(conn, 403)
    end

    test "success update person", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      party = insert(:prm, :party, tax_id: "2222222220")
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      expect(MPIMock, :update_person, fn id, _params, _headers ->
        get_person(id, 200)
      end)

      conn =
        conn
        |> put_req_header("edrpou", "2222222220")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
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
                  },
                  %{
                    "type" => "REGISTRATION",
                    "zip" => "02090",
                    "settlement_type" => "CITY",
                    "country" => "UA",
                    "settlement" => "KYIV",
                    "area" => "KYIV",
                    "settlement_id" => UUID.generate(),
                    "building" => "15"
                  }
                ],
                "authentication_methods" => [%{"type" => "OTP", "phone_number" => "+380991112233"}],
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

  describe "get person details" do
    test "no required header", %{conn: conn} do
      conn = get(conn, cabinet_persons_path(conn, :personal_info))
      assert resp = json_response(conn, 401)
      assert %{"error" => %{"type" => "access_denied", "message" => "Missing header x-consumer-metadata"}} = resp
    end

    test "returns person detail for logged user", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{
          id: "c8912855-21c3-4771-ba18-bcd8e524f14c",
          first_name: "Алекс",
          last_name: "Джонс",
          second_name: "Петрович"
        })
      end)

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: legal_entity.id}))

      conn = get(conn, cabinet_persons_path(conn, :personal_info))
      response_data = json_response(conn, 200)["data"]

      assert "c8912855-21c3-4771-ba18-bcd8e524f14c" == response_data["id"]
      assert "Алекс" == response_data["first_name"]
      assert "Джонс" == response_data["last_name"]
      assert "Петрович" == response_data["second_name"]
    end
  end

  describe "create declaration request online" do
    test "success create declaration request online", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      person_id = "c8912855-21c3-4771-ba18-bcd8e524f14c"
      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_speciality = Map.put(speciality(), "speciality", "PEDIATRICIAN")
      additional_info = Map.put(doctor(), "specialities", [employee_speciality])

      employee =
        insert(
          :prm,
          :employee,
          division: division,
          legal_entity_id: legal_entity.id,
          additional_info: additional_info,
          speciality: employee_speciality
        )

      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c", party: employee.party)

      expect(ManMock, :render_template, fn _id, _data ->
        {:ok, "<html><body>Printout form for declaration request.</body></html>"}
      end)

      conn =
        conn
        |> put_req_header("edrpou", "2222222220")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: legal_entity.id}))
        |> post(cabinet_declarations_path(conn, :create_declaration_request), %{
          person_id: person_id,
          employee_id: employee.id,
          division_id: employee.division.id
        })

      assert %{"data" => %{"seed" => "some_current_hash"}} = json_response(conn, 200)
    end
  end

  describe "terminate declaration" do
    test "success terminate declaration", %{conn: conn} do
      %{party: party} = insert(:prm, :party_user)
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      %{id: employee_id} = insert(:prm, :employee, party: party, legal_entity: legal_entity)
      %{id: division_id} = insert(:prm, :division, legal_entity: legal_entity)

      {declaration, _} =
        get_declaration(
          %{
            id: "0cd6a6f0-9a71-4aa7-819d-6c158201a282",
            legal_entity_id: legal_entity.id,
            division_id: division_id,
            employee_id: employee_id,
            person_id: "c8912855-21c3-4771-ba18-bcd8e524f14c"
          },
          200
        )

      expect(OPSMock, :get_declaration_by_id, fn _params, _headers ->
        declaration
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200)
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200)
      end)

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: legal_entity.id}))
        |> patch(cabinet_declarations_path(conn, :terminate_declaration, "0cd6a6f0-9a71-4aa7-819d-6c158201a282"))

      assert %{"data" => %{"id" => "0cd6a6f0-9a71-4aa7-819d-6c158201a282", "status" => "terminated"}} =
               json_response(conn, 200)
    end
  end

  describe "get declaration details" do
    test "successfully get declaration details by id", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")
      insert(:prm, :division, id: "21f22e09-8dd9-4ca4-bcc7-72994ef2850a", legal_entity: legal_entity)
      party = insert(:prm, :party)
      insert(:prm, :employee, id: "5753a279-8f8c-42b9-8f4d-57b38cabe55d", party: party)

      resp =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: legal_entity.id}))
        |> get(cabinet_declarations_path(conn, :show_declaration, "0cd6a6f0-9a71-4aa7-819d-6c158201a282"))
        |> json_response(200)

      data = resp["data"]

      assert data["id"] == "0cd6a6f0-9a71-4aa7-819d-6c158201a282"
      assert data["division"]["id"] == "21f22e09-8dd9-4ca4-bcc7-72994ef2850a"
      assert data["employee"]["id"] == "5753a279-8f8c-42b9-8f4d-57b38cabe55d"
      assert data["legal_entity"]["id"] == "c3cc1def-48b6-4451-be9d-3b777ef06ff9"
      assert data["person"]["id"] == "c8912855-21c3-4771-ba18-bcd8e524f14c"
    end
  end

  describe "person details" do
    test "no required header", %{conn: conn} do
      conn = get(conn, cabinet_persons_path(conn, :person_details))
      assert resp = json_response(conn, 401)
      assert %{"error" => %{"type" => "access_denied", "message" => "Missing header x-consumer-metadata"}} = resp
    end

    test "success get person details", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{
          id: "c8912855-21c3-4771-ba18-bcd8e524f14c",
          first_name: "Алекс",
          second_name: "Петрович",
          addresses: [
            %{
              "zip" => "02090",
              "type" => "REGISTRATION",
              "street_type" => "STREET",
              "street" => "Ніжинська",
              "settlement_type" => "CITY",
              "settlement_id" => "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
              "settlement" => "СОРОКИ-ЛЬВІВСЬКІ",
              "region" => "ПУСТОМИТІВСЬКИЙ",
              "country" => "UA",
              "building" => "15",
              "area" => "ЛЬВІВСЬКА",
              "apartment" => "23"
            },
            %{
              "zip" => "02090",
              "type" => "RESIDENCE",
              "street_type" => "STREET",
              "street" => "Ніжинська",
              "settlement_type" => "CITY",
              "settlement_id" => "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
              "settlement" => "СОРОКИ-ЛЬВІВСЬКІ",
              "region" => "ПУСТОМИТІВСЬКИЙ",
              "country" => "UA",
              "building" => "15",
              "area" => "ЛЬВІВСЬКА",
              "apartment" => "23"
            }
          ],
          birth_country: "string value",
          birth_settlement: "string value",
          gender: "string value",
          email: "test@example.com",
          tax_id: "2222222225",
          documents: [%{"type" => "BIRTH_CERTIFICATE", "number" => "1234567890"}],
          phones: [%{"type" => "MOBILE", "number" => "+380972526080"}],
          secret: "string value",
          emergency_contact: %{},
          process_disclosure_data_consent: true,
          authentication_methods: [%{"type" => "NA"}],
          preferred_way_communication: "––"
        })
      end)

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: legal_entity.id}))

      response =
        conn
        |> get(cabinet_persons_path(conn, :person_details))
        |> json_response(200)

      data = response["data"]

      assert data["id"] == "c8912855-21c3-4771-ba18-bcd8e524f14c"
      assert data["first_name"] == "Алекс"
      assert data["second_name"] == "Петрович"
      assert Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, data["birth_date"])
      assert data["birth_country"] == "string value"
      assert data["birth_settlement"] == "string value"
      assert data["gender"] == "string value"
      assert data["email"] == "test@example.com"
      assert data["tax_id"] == "2222222225"
      assert data["documents"] == [%{"type" => "BIRTH_CERTIFICATE", "number" => "1234567890"}]

      assert Enum.count(data["addresses"]) == 2

      assert Enum.all?(data["addresses"], fn address ->
               address["settlement_id"] == "707dbc55-cb6b-4aaa-97c1-2a1e03476100"
             end)

      assert data["phones"] == [%{"type" => "MOBILE", "number" => "+380972526080"}]
      assert data["secret"] == "string value"
      assert data["emergency_contact"] == %{}
      assert data["process_disclosure_data_consent"] == true
      assert data["authentication_methods"] == [%{"type" => "NA"}]
      assert data["preferred_way_communication"] == "––"
    end
  end

  defp get_declaration(params, response_status) do
    declaration = build(:declaration, params)
    declaration_id = declaration.id

    declaration =
      declaration
      |> Poison.encode!()
      |> Poison.decode!()

    {{:ok, %{"data" => declaration, "meta" => %{"code" => response_status}}}, declaration_id}
  end

  defp get_person(id, response_status, params \\ %{}) do
    params = Map.put(params, :id, id)
    person = build(:person, params)

    person =
      person
      |> Poison.encode!()
      |> Poison.decode!()

    {:ok, %{"data" => person, "meta" => %{"code" => response_status}}}
  end
end
