defmodule EHealth.Web.Cabinet.PersonsControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import EHealth.Expectations.Signature
  import Mox

  alias Ecto.UUID

  setup :verify_on_exit!

  describe "update person" do
    test "no required header", %{conn: conn} do
      conn = patch(conn, cabinet_persons_path(conn, :update_person, UUID.generate()))
      assert resp = json_response(conn, 401)
      assert %{"error" => %{"type" => "access_denied", "message" => "Missing header x-consumer-metadata"}} = resp
    end

    test "invalid params", %{conn: conn} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c",
             "tax_id" => "2222222225"
           }
         }}
      end)

      legal_entity = insert(:prm, :legal_entity)

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

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
      cabinet()
      legal_entity = insert(:prm, :legal_entity)

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c",
             "tax_id" => "2222222225"
           }
         }}
      end)

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      invalid_signed_content()

      conn =
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64("invalid")
        })

      %{"error" => %{"invalid" => [%{"rules" => [%{"description" => error_description}]}]}} = json_response(conn, 422)
      assert "Not a base64 string" == error_description
    end

    test "tax_id doesn't match with signed content", %{conn: conn} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c",
             "tax_id" => "2222222225"
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _ ->
        {:ok, %{"data" => %{"id" => id, "tax_id" => "3378115538"}}}
      end)

      drfo_signed_content(%{}, "3378115538")
      legal_entity = insert(:prm, :legal_entity)
      party = insert(:prm, :party)
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Jason.encode!(%{}))
        })

      assert resp = json_response(conn, 422)

      assert [
               %{
                 "entry" => "$.data",
                 "entry_type" => "json_data_property",
                 "rules" => [
                   %{
                     "description" =>
                       "Person that logged in, person that is changed and person that sign should be the same",
                     "params" => [],
                     "rule" => "invalid"
                   }
                 ]
               }
             ] == resp["error"]["invalid"]
    end

    test "tax_id doesn't match with signer", %{conn: conn} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c",
             "tax_id" => "2222222225"
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _ ->
        {:ok, %{"data" => %{"id" => id, "tax_id" => "2222222220"}}}
      end)

      drfo_signed_content(%{"tax_id" => "2222222220"}, "2222222220")
      legal_entity = insert(:prm, :legal_entity)
      party = insert(:prm, :party)
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Jason.encode!(%{"tax_id" => "2222222220"}))
        })

      assert resp = json_response(conn, 422)

      assert [
               %{
                 "entry" => "$.data",
                 "entry_type" => "json_data_property",
                 "rules" => [
                   %{
                     "description" =>
                       "Person that logged in, person that is changed and person that sign should be the same",
                     "params" => [],
                     "rule" => "invalid"
                   }
                 ]
               }
             ] == resp["error"]["invalid"]
    end

    test "invalid signed content changeset", %{conn: conn} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c",
             "tax_id" => "2222222225"
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _ ->
        {:ok, %{"data" => %{"id" => id, "tax_id" => "2222222225"}}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      party = insert(:prm, :party, tax_id: "2222222225")
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")
      drfo_signed_content(%{"tax_id" => "2222222225"}, "2222222225")

      conn =
        conn
        |> put_req_header("drfo", "2222222225")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Jason.encode!(%{"tax_id" => "2222222225"}))
        })

      assert json_response(conn, 422)
    end

    test "user person_id doesn't match query param id", %{conn: conn} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => UUID.generate(),
             "tax_id" => "2222222225"
           }
         }}
      end)

      legal_entity = insert(:prm, :legal_entity)

      conn =
        conn
        |> put_req_header("x-consumer-id", "668d1541-e4cf-4a95-a25a-60d83864ceaf")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Jason.encode!(%{}))
        })

      assert json_response(conn, 403)
    end

    test "invalid client_type", %{conn: conn} do
      msp()
      legal_entity = insert(:prm, :legal_entity)

      conn =
        conn
        |> put_req_header("x-consumer-id", "668d1541-e4cf-4a95-a25a-60d83864ceaf")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn = patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{})
      assert json_response(conn, 403)
    end

    test "success update person", %{conn: conn} do
      cabinet()

      expect(MPIMock, :person, fn id, _ ->
        {:ok, %{"data" => %{"id" => id, "tax_id" => "2222222225"}}}
      end)

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c",
             "tax_id" => "2222222225"
           }
         }}
      end)

      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      party = insert(:prm, :party, tax_id: "2222222225")
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      expect(MPIMock, :update_person, fn id, _params, _headers ->
        get_person(id, 200, %{addresses: get_person_addresses()})
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      conn =
        conn
        |> put_req_header("drfo", "2222222225")
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      data = %{
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
            "settlement" => "Київ",
            "area" => "Житомирська",
            "settlement_id" => UUID.generate(),
            "building" => "15",
            "region" => "Бердичівський"
          },
          %{
            "type" => "REGISTRATION",
            "zip" => "02090",
            "settlement_type" => "CITY",
            "country" => "UA",
            "settlement" => "Київ",
            "area" => "Житомирська",
            "settlement_id" => UUID.generate(),
            "building" => "15",
            "region" => "Бердичівський"
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
        "tax_id" => "2222222225"
      }

      expect(UAddressesMock, :validate_addresses, fn _, _ ->
        {:ok, %{"data" => %{}}}
      end)

      drfo_signed_content(data, "2222222225")

      conn =
        patch(conn, cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Jason.encode!(data))
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

    test "tax_id are different in user and person", %{conn: conn} do
      cabinet()
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c",
             "tax_id" => "2222222225"
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{
          id: "c8912855-21c3-4771-ba18-bcd8e524f14c",
          first_name: "Алекс",
          last_name: "Джонс",
          second_name: "Петрович",
          tax_id: "2222222220"
        })
      end)

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn = get(conn, cabinet_persons_path(conn, :personal_info))
      assert resp = json_response(conn, 401)
      assert %{"error" => %{"type" => "access_denied", "message" => "Person not found"}} = resp
    end

    test "returns person detail for logged user", %{conn: conn} do
      cabinet()
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c",
             "tax_id" => "2222222225",
             "is_blocked" => false
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{
          id: "c8912855-21c3-4771-ba18-bcd8e524f14c",
          first_name: "Алекс",
          last_name: "Джонс",
          second_name: "Петрович",
          tax_id: "2222222225"
        })
      end)

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn = get(conn, cabinet_persons_path(conn, :personal_info))
      response_data = json_response(conn, 200)["data"]

      assert "c8912855-21c3-4771-ba18-bcd8e524f14c" == response_data["id"]
      assert "Алекс" == response_data["first_name"]
      assert "Джонс" == response_data["last_name"]
      assert "Петрович" == response_data["second_name"]
    end
  end

  describe "person details" do
    test "no required header", %{conn: conn} do
      conn = get(conn, cabinet_persons_path(conn, :person_details))
      assert resp = json_response(conn, 401)
      assert %{"error" => %{"type" => "access_denied", "message" => "Missing header x-consumer-metadata"}} = resp
    end

    test "tax_id are different in user and person", %{conn: conn} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c",
             "tax_id" => "2222222225"
           }
         }}
      end)

      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{
          id: "c8912855-21c3-4771-ba18-bcd8e524f14c",
          first_name: "Алекс",
          second_name: "Петрович",
          birth_country: "string value",
          birth_settlement: "string value",
          gender: "string value",
          email: "test@example.com",
          tax_id: "2222222220",
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
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn = get(conn, cabinet_persons_path(conn, :person_details))
      assert resp = json_response(conn, 401)
      assert %{"error" => %{"type" => "access_denied", "message" => "Person not found"}} = resp
    end

    test "success get person details", %{conn: conn} do
      cabinet()
      legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c",
             "tax_id" => "2222222225"
           }
         }}
      end)

      expect(MPIMock, :person, fn id, _headers ->
        get_person(id, 200, %{
          id: "c8912855-21c3-4771-ba18-bcd8e524f14c",
          first_name: "Алекс",
          second_name: "Петрович",
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
          preferred_way_communication: "––",
          addresses: get_person_addresses()
        })
      end)

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

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
               address["settlement_id"] == "adaa4abf-f530-461c-bcbf-a0ac210d955b"
             end)

      assert data["phones"] == [%{"type" => "MOBILE", "number" => "+380972526080"}]
      assert data["secret"] == "string value"
      assert data["emergency_contact"] == %{}
      assert data["process_disclosure_data_consent"] == true
      assert data["authentication_methods"] == [%{"type" => "NA"}]
      assert data["preferred_way_communication"] == "––"
    end
  end

  defp get_person(id, response_status, params) do
    params = Map.put(params, :id, id)
    person = string_params_for(:person, params)

    {:ok, %{"data" => person, "meta" => %{"code" => response_status}}}
  end

  defp get_person_addresses do
    [
      build(:address, %{"type" => "REGISTRATION"}),
      build(:address, %{"type" => "RESIDENCE"})
    ]
  end
end
