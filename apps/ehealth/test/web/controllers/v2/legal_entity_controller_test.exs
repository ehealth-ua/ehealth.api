defmodule EHealth.Web.V2.LegalEntityControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  import Mox
  import Core.Expectations.Signature
  import Core.Expectations.Man
  import Core.Expectations.Mithril

  alias Core.LegalEntities.LegalEntity
  alias Core.LegalEntities.License
  alias Ecto.UUID

  @msp LegalEntity.type(:msp)
  @pharmacy LegalEntity.type(:pharmacy)

  setup :verify_on_exit!
  setup :set_mox_global

  describe "create or update legal entity" do
    test "invalid legal entity", %{conn: conn} do
      conn = put(conn, v2_legal_entity_path(conn, :create_or_update), %{"invalid" => "data"})
      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      assert resp["error"]
    end

    test "fail to create legal entity with invalid drfo", %{conn: conn} do
      insert_dictionaries()
      legal_entity_params = Map.put(get_legal_entity_data(), "edrpou", "01234АЄ")
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      drfo_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      resp =
        conn
        |> put(v2_legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.edrpou",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "string does not match pattern \"^[0-9]{8,10}|[0-9]{9,10}$\"",
                       "rule" => "format"
                     }
                   ]
                 }
               ],
               "type" => "validation_failed"
             } = resp["error"]
    end

    test "fail to create legal entity without edrpou / drfo in signature", %{conn: conn} do
      validate_addresses()
      insert_dictionaries()
      legal_entity_params = get_legal_entity_data()
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)

      expect(SignatureMock, :decode_and_validate, fn _, _ ->
        {:ok,
         %{
           "content" => legal_entity_params,
           "signatures" => [
             %{
               "is_valid" => true,
               "signer" => %{}
             }
           ]
         }}
      end)

      resp =
        conn
        |> put(v2_legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(422)

      assert [%{"rules" => [%{"description" => "EDRPOU and DRFO is empty in digital sign"}]}] = resp["error"]["invalid"]
    end

    test "fail to create legal entity when signature is invalid", %{conn: conn} do
      insert_dictionaries()
      legal_entity_params = get_legal_entity_data()
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)

      invalid_signed_content()

      resp =
        conn
        |> put(v2_legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(422)

      assert [%{"rules" => [%{"description" => "Not a base64 string"}], "entry" => "$.signed_legal_entity_request"}] =
               resp["error"]["invalid"]
    end

    test "fail to create legal_entity with pharmacy type without licence_number", %{conn: conn} do
      legal_entity_params =
        get_legal_entity_data()
        |> Map.put("type", LegalEntity.type(:pharmacy))
        |> put_in(~w(license type), License.type(:pharmacy))

      {_, legal_entity_params} = pop_in(legal_entity_params, ~w(license license_number))
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      resp =
        conn
        |> put(v2_legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(422)

      assert %{"error" => %{"invalid" => [%{"entry" => "$.license.license_number"}]}} = resp
    end

    test "create legal entity with type PRIMARY_CARE", %{conn: conn} do
      get_client_type_by_name()
      put_client()
      upsert_client_connection()
      validate_addresses()
      insert_dictionaries()
      legal_entity_params = get_legal_entity_data()
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_search_legal_entity({:ok, [%{"state" => 1, "id" => 1}]})
      template()

      expect_get_legal_entity_detailed_info(
        {:ok,
         %{
           "id" => 1,
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{
             "name" => "test",
             "display" => "foo"
           },
           "activity_kinds" => [
             %{
               "name" => "Видання іншого програмного забезпечення",
               "code" => "58.29",
               "is_primary" => false
             }
           ],
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      resp =
        conn
        |> put(v2_legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(200)

      assert "PRIMARY_CARE" == resp["data"]["type"]
    end

    test "create legal entity sign edrpou", %{conn: conn} do
      get_client_type_by_name()
      put_client()
      upsert_client_connection()
      validate_addresses()

      insert_dictionaries()
      legal_entity_params = get_legal_entity_data()
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_search_legal_entity({:ok, [%{"state" => 1, "id" => 1}]})
      template()

      expect_get_legal_entity_detailed_info(
        {:ok,
         %{
           "id" => 1,
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{
             "name" => "test",
             "display" => "foo"
           },
           "activity_kinds" => [
             %{
               "name" => "Видання іншого програмного забезпечення",
               "code" => "58.29",
               "is_primary" => false
             }
           ],
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      resp =
        conn
        |> put(v2_legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(200)

      assert resp
    end

    test "create legal entity sign drfo code", %{conn: conn} do
      get_client_type_by_name()
      put_client()
      upsert_client_connection()

      validate_addresses()

      insert_dictionaries()
      legal_entity_params = Map.put(get_legal_entity_data(), "edrpou", "123456789")
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      drfo_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_search_legal_entity({:ok, [%{"state" => 1, "id" => 1}]})
      template()

      expect_get_legal_entity_detailed_info(
        {:ok,
         %{
           "id" => 1,
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{
             "name" => "test",
             "display" => "foo"
           },
           "activity_kinds" => [
             %{
               "name" => "Видання іншого програмного забезпечення",
               "code" => "58.29",
               "is_primary" => false
             }
           ],
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      resp =
        conn
        |> put(v2_legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(200)

      assert resp
    end

    test "create legal entity sign drfo code when edrpou empty string", %{conn: conn} do
      get_client_type_by_name()
      put_client()
      upsert_client_connection()
      validate_addresses()

      insert_dictionaries()
      legal_entity_params = Map.put(get_legal_entity_data(), "edrpou", "123456789")
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)

      expect(SignatureMock, :decode_and_validate, fn _, _ ->
        {:ok,
         %{
           "content" => legal_entity_params,
           "signatures" =>
             Enum.map([legal_entity_params["edrpou"]], fn drfo ->
               %{"is_valid" => true, "signer" => %{"drfo" => drfo, "edrpou" => ""}}
             end)
         }}
      end)

      expect_search_legal_entity({:ok, [%{"state" => 1, "id" => 1}]})
      template()

      expect_get_legal_entity_detailed_info(
        {:ok,
         %{
           "id" => 1,
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{
             "name" => "test",
             "display" => "foo"
           },
           "activity_kinds" => [
             %{
               "name" => "Видання іншого програмного забезпечення",
               "code" => "58.29",
               "is_primary" => false
             }
           ],
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      resp =
        conn
        |> put(v2_legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(200)

      assert resp
    end

    test "create legal entity sign drfo code when edrpou nil", %{conn: conn} do
      get_client_type_by_name()
      put_client()
      upsert_client_connection()

      validate_addresses()

      insert_dictionaries()
      legal_entity_params = Map.put(get_legal_entity_data(), "edrpou", "123456789")
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)

      expect(SignatureMock, :decode_and_validate, fn _, _ ->
        {:ok,
         %{
           "content" => legal_entity_params,
           "signatures" =>
             Enum.map([legal_entity_params["edrpou"]], fn drfo ->
               %{"is_valid" => true, "signer" => %{"drfo" => drfo, "edrpou" => nil}}
             end)
         }}
      end)

      expect_search_legal_entity({:ok, [%{"state" => 1, "id" => 1}]})
      template()

      expect_get_legal_entity_detailed_info(
        {:ok,
         %{
           "id" => 1,
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{
             "name" => "test",
             "display" => "foo"
           },
           "activity_kinds" => [
             %{
               "name" => "Видання іншого програмного забезпечення",
               "code" => "58.29",
               "is_primary" => false
             }
           ],
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      assert %{"data" => resp_data} =
               conn
               |> put(v2_legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
               |> json_response(200)

      assert %{"nhs_reviewed" => false, "nhs_verified" => false} = resp_data
    end

    test "update legal entity sign drfo code when edrpou nil", %{conn: conn} do
      %{edrpou: edrpou} = insert(:prm, :legal_entity)

      get_client_type_by_name()
      put_client()
      upsert_client_connection()

      validate_addresses()

      insert_dictionaries()
      legal_entity_params = Map.put(get_legal_entity_data(), "edrpou", edrpou)
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)

      expect(SignatureMock, :decode_and_validate, fn _, _ ->
        {:ok,
         %{
           "content" => legal_entity_params,
           "signatures" =>
             Enum.map([legal_entity_params["edrpou"]], fn drfo ->
               %{"is_valid" => true, "signer" => %{"drfo" => drfo, "edrpou" => nil}}
             end)
         }}
      end)

      expect_search_legal_entity({:ok, [%{"state" => 1, "id" => 1}]})
      template()

      expect_get_legal_entity_detailed_info(
        {:ok,
         %{
           "id" => 1,
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{
             "name" => "test",
             "display" => "foo"
           },
           "activity_kinds" => [
             %{
               "name" => "Видання іншого програмного забезпечення",
               "code" => "58.29",
               "is_primary" => false
             }
           ],
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      assert %{"data" => resp_data} =
               conn
               |> put(v2_legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
               |> json_response(200)

      assert %{"nhs_reviewed" => false, "nhs_verified" => false, "edr_verified" => nil} = resp_data
    end

    test "fail to create legal entity sign drfo passport number is not allowed", %{conn: conn} do
      insert_dictionaries()
      legal_entity_params = Map.put(get_legal_entity_data(), "edrpou", "ЯЁ756475")
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      drfo_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      resp =
        conn
        |> put(v2_legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.edrpou",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "string does not match pattern \"^[0-9]{8,10}|[0-9]{9,10}$\"",
                       "rule" => "format"
                     }
                   ]
                 }
               ],
               "type" => "validation_failed"
             } = resp["error"]
    end

    test "fail to create legal entity edrpou is not match with signer", %{conn: conn} do
      validate_addresses()
      insert_dictionaries()
      legal_entity_params = Map.put(get_legal_entity_data(), "edrpou", "7564750099")
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      drfo_signed_content(legal_entity_params, "0123456789")

      resp =
        conn
        |> put(v2_legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.drfo",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "DRFO does not match signer drfo",
                       "params" => ["0123456789"],
                       "rule" => "inclusion"
                     }
                   ]
                 }
               ],
               "type" => "validation_failed"
             } = resp["error"]
    end

    test "fail to create legal entity when get EDR API error", %{conn: conn} do
      validate_addresses()
      insert_dictionaries()

      legal_entity_params = get_legal_entity_data()
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_search_legal_entity({:error, :timeout})

      resp =
        conn
        |> put(v2_legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(409)

      assert get_in(resp, ~w(error message)) == "Legal Entity not found in EDR"
    end

    test "fail to create legal entity when EDR API returns response with invalid legal entity status", %{conn: conn} do
      validate_addresses()
      insert_dictionaries()

      legal_entity_params = get_legal_entity_data()
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_search_legal_entity({:ok, [%{"state" => 0, "id" => 1}]})

      resp =
        conn
        |> put(v2_legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.data.edrpou",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Provided EDRPOU is not active in EDR",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ],
               "type" => "validation_failed"
             } = resp["error"]
    end
  end

  describe "update legal_entity type flow" do
    test "MSP to MSP", %{conn: conn} do
      get_client_type_by_name()
      put_client()
      upsert_client_connection()
      validate_addresses()

      legal_entity = insert(:prm, :legal_entity, type: @msp)

      legal_entity_params =
        Map.merge(get_legal_entity_data(), %{"website" => "https://new.example.com", "edrpou" => legal_entity.edrpou})

      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_search_legal_entity({:ok, [%{"state" => 1, "id" => 1}]})
      template()

      expect_get_legal_entity_detailed_info(
        {:ok,
         %{
           "id" => 1,
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{
             "name" => "test",
             "display" => "foo"
           },
           "activity_kinds" => [
             %{
               "name" => "Видання іншого програмного забезпечення",
               "code" => "58.29",
               "is_primary" => false
             }
           ],
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      assert conn
             |> put(v2_legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
             |> json_response(200)
    end

    test "PHARMACY to PHARMACY", %{conn: conn} do
      get_client_type_by_name()
      put_client()
      upsert_client_connection()
      validate_addresses()

      legal_entity = insert(:prm, :legal_entity, type: @pharmacy)

      legal_entity_params =
        Map.merge(get_legal_entity_data(), %{"website" => "https://new.example.com", "edrpou" => legal_entity.edrpou})

      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_search_legal_entity({:ok, [%{"state" => 1, "id" => 1}]})
      template()

      expect_get_legal_entity_detailed_info(
        {:ok,
         %{
           "id" => 1,
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{
             "name" => "test",
             "display" => "foo"
           },
           "activity_kinds" => [
             %{
               "name" => "Видання іншого програмного забезпечення",
               "code" => "58.29",
               "is_primary" => false
             }
           ],
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      assert conn
             |> put(v2_legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
             |> json_response(200)
    end
  end

  describe "create or update legal enitity new validations" do
    test "license wrong type", %{conn: conn} do
      insert_dictionaries()
      validate_addresses()
      legal_entity_params = put_in(get_legal_entity_data(), ~w(license type), License.type(:pharmacy))
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_search_legal_entity({:ok, [%{"state" => 1, "id" => 1}]})

      expect_get_legal_entity_detailed_info(
        {:ok,
         %{
           "id" => 1,
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{
             "name" => "test",
             "display" => "foo"
           },
           "activity_kinds" => [
             %{
               "name" => "Видання іншого програмного забезпечення",
               "code" => "58.29",
               "is_primary" => false
             }
           ],
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      resp =
        conn
        |> put(v2_legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(409)

      assert resp["error"]["message"] == "Legal entity type and license type mismatch"
    end
  end

  describe "get legal entities" do
    setup %{conn: conn} do
      insert(:prm, :legal_entity)
      insert(:prm, :legal_entity)
      %{conn: conn}
    end

    test "with x-consumer-metadata that contains MIS client_id", %{conn: conn} do
      msp()
      %{id: id, edrpou: edrpou} = insert(:prm, :legal_entity)

      resp =
        conn
        |> put_client_id_header(id)
        |> get(v2_legal_entity_path(conn, :index, edrpou: edrpou))
        |> json_response(200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert_list_response_schema(resp["data"], "legal_entity")

      Enum.each(resp["data"], fn resp_entity ->
        assert %{"nhs_verified" => _, "nhs_reviewed" => _} = resp_entity
      end)

      assert_list_response_schema(resp["data"], "legal_entity")
      assert 1 == length(resp["data"])
    end

    test "with x-consumer-metadata that contains NHS client_id", %{conn: conn} do
      nhs()
      %{id: id, edrpou: edrpou} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get(conn, v2_legal_entity_path(conn, :index, edrpou: edrpou))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
    end

    test "with not MIS client_id that matches one of legal entities id", %{conn: conn} do
      msp()
      insert(:prm, :legal_entity)
      %{id: id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get(conn, v2_legal_entity_path(conn, :index))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
      assert id == hd(resp["data"])["id"]
    end

    test "search by type msp", %{conn: conn} do
      msp()
      insert(:prm, :legal_entity)
      %{id: id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get(conn, v2_legal_entity_path(conn, :index, type: LegalEntity.type(:msp)))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
      assert id == hd(resp["data"])["id"]
    end

    test "search by type msp_pharmacy", %{conn: conn} do
      msp()
      %{id: id} = insert(:prm, :legal_entity, type: LegalEntity.type(:msp_pharmacy))
      conn = put_client_id_header(conn, id)
      conn = get(conn, v2_legal_entity_path(conn, :index, type: LegalEntity.type(:msp_pharmacy)))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
      assert id == hd(resp["data"])["id"]
    end

    test "render with edr_data", %{conn: conn} do
      msp()

      address = %{
        type: "RESIDENCE",
        country: "UA",
        area: "Житомирська",
        region: "Бердичівський",
        settlement: "Київ",
        settlement_type: "CITY",
        settlement_id: UUID.generate(),
        street_type: "STREET",
        street: "вул. Ніжинська",
        building: "15-В",
        apartment: "23",
        zip: "02090"
      }

      legal_entity = build(:legal_entity, residence_address: address)
      edr_data = insert(:prm, :edr_data, legal_entities: [legal_entity])
      id = edr_data.legal_entities |> hd() |> Map.get(:id)
      conn = put_client_id_header(conn, id)
      conn = get(conn, v2_legal_entity_path(conn, :index))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
      assert id == hd(resp["data"])["id"]
      assert edr = hd(resp["data"])["edr"]
      assert Enum.all?(~w(id name), &Map.has_key?(edr, &1))
    end

    test "with x-consumer-metadata that contains client_id that does not match legal entity id", %{conn: conn} do
      msp()
      conn = put_client_id_header(conn, Ecto.UUID.generate())
      id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = get(conn, v2_legal_entity_path(conn, :index, legal_entity_id: id))
      resp = json_response(conn, 200)
      assert [] == resp["data"]
      assert Map.has_key?(resp, "paging")
      assert String.contains?(resp["meta"]["url"], "/legal_entities")
    end

    test "with client_id that does not exists", %{conn: conn} do
      expect(MithrilMock, :get_client_type_name, fn _, _ -> {:error, :access_denied} end)
      conn = put_client_id_header(conn, UUID.generate())
      id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = get(conn, v2_legal_entity_path(conn, :index, legal_entity_id: id))
      json_response(conn, 401)
    end
  end

  describe "get legal entity by id" do
    test "check required legal entity fields", %{conn: conn} do
      msp()
      %{id: id} = insert(:prm, :legal_entity, nhs_verified: false)

      resp =
        conn
        |> put_client_id_header(id)
        |> get(v2_legal_entity_path(conn, :show, id))
        |> json_response(200)

      assert match?(%{"nhs_reviewed" => _}, resp["data"])
      refute resp["data"]["nhs_verified"]
    end

    test "with x-consumer-metadata that contains client_id that matches legal entity id", %{conn: conn} do
      msp()
      %{id: id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get(conn, v2_legal_entity_path(conn, :show, id))
      resp = json_response(conn, 200)

      assert id == resp["data"]["id"]
      assert Map.has_key?(resp["data"], "edr")
      assert Map.has_key?(resp["data"], "website")
      assert Map.has_key?(resp["data"], "archive")
      assert Map.has_key?(resp["data"], "beneficiary")
      assert Map.has_key?(resp["data"], "receiver_funds_code")
      refute Map.has_key?(resp, "paging")
    end

    test "with x-consumer-metadata that contains MIS client_id that does not match legal entity id", %{conn: conn} do
      mis()
      %{id: id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get(conn, v2_legal_entity_path(conn, :show, id))
      resp = json_response(conn, 200)

      assert id == resp["data"]["id"]
      assert Map.has_key?(resp["data"], "edr")
      refute Map.has_key?(resp, "paging")
    end

    test "with x-consumer-metadata that contains client_id that matches inactive legal entity id", %{conn: conn} do
      msp()
      %{id: id} = insert(:prm, :legal_entity, is_active: false)
      conn = put_client_id_header(conn, id)
      conn = get(conn, v2_legal_entity_path(conn, :show, id))
      assert 404 == json_response(conn, 404)["meta"]["code"]
    end

    test "with client_id that does not exists", %{conn: conn} do
      expect(MithrilMock, :get_client_type_name, fn _, _ -> {:error, :access_denied} end)
      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, v2_legal_entity_path(conn, :show, UUID.generate()))
      json_response(conn, 401)
    end
  end

  # ToDo: not used, but should
  def assert_security_in_urgent_response(resp) do
    assert Map.has_key?(resp, "urgent")
    assert Map.has_key?(resp["urgent"], "security")
    security = resp["urgent"]["security"]

    Enum.each(~w(redirect_uri client_id client_secret), fn field ->
      assert Map.has_key?(security, field), "Field `#{field}` required in urgent.security"
      assert Map.get(security, field), "Field `#{field}` is empty in urgent.security"
    end)
  end

  defp validate_addresses(n \\ 1) do
    expect_uaddresses_validate(:ok, n)
  end

  defp insert_dictionaries do
    insert(:il, :dictionary_phone_type)
    insert(:il, :dictionary_address_type)
    insert(:il, :dictionary_document_type)
  end

  defp get_legal_entity_data do
    "../core/test/data/v2/legal_entity.json"
    |> File.read!()
    |> Jason.decode!()
  end

  defp sign_legal_entity(request_params) do
    %{
      "signed_legal_entity_request" => Base.encode64(Jason.encode!(request_params)),
      "signed_content_encoding" => "base64"
    }
  end
end
