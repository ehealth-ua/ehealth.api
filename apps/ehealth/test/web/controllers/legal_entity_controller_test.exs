defmodule EHealth.Web.LegalEntityControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  import Mox
  import Core.Expectations.Man
  import Core.Expectations.Mithril
  import Core.Expectations.RPC
  import Core.Expectations.Signature

  alias Ecto.UUID
  alias Core.PRMRepo
  alias Core.Employees.Employee
  alias Core.LegalEntities
  alias Core.LegalEntities.LegalEntity
  alias Core.Contracts.CapitationContract

  @legal_entity_type_pharmacy LegalEntity.type(:pharmacy)
  @kveds_allowed_pharmacy "47.73"

  setup :verify_on_exit!
  setup :set_mox_global

  describe "create or update legal entity" do
    test "invalid legal entity", %{conn: conn} do
      conn = put(conn, legal_entity_path(conn, :create_or_update), %{"invalid" => "data"})
      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      assert resp["error"]
    end

    test "fail to create legal entity with invalid drfo", %{conn: conn} do
      insert_dictionaries()
      legal_entity_type = "MSP"
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => legal_entity_type, "edrpou" => "01234АЄ"})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      drfo_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      resp =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
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
      legal_entity_type = "MSP"
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => legal_entity_type})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)

      expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
        {:ok,
         %{
           "data" => %{
             "content" => legal_entity_params,
             "signatures" => [
               %{
                 "is_valid" => true,
                 "signer" => %{}
               }
             ]
           }
         }}
      end)

      resp =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(422)

      assert [%{"rules" => [%{"description" => "EDRPOU and DRFO is empty in digital sign"}]}] = resp["error"]["invalid"]
    end

    test "fail to create legal entity with wrong type", %{conn: conn} do
      insert_dictionaries()
      invalid_legal_entity_type = "MIS"
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => invalid_legal_entity_type})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      resp =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(422)

      assert resp
      assert resp["error"]["message"] == "Only legal_entity with type MSP or Pharmacy could be created"
    end

    test "fail to create legal_entity with pharmacy type without licence_number", %{conn: conn} do
      {_, legal_entity_params} =
        get_legal_entity_data()
        |> Map.merge(%{"type" => @legal_entity_type_pharmacy})
        |> pop_in(["medical_service_provider", "licenses", Access.all(), "license_number"])

      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      resp =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(422)

      assert %{"error" => %{"invalid" => [%{"entry" => "$.medical_service_provider.licenses.0.license_number"}]}} = resp
    end

    test "create legal entity with type pharmacy", %{conn: conn} do
      get_client_type_by_name()
      put_client()
      upsert_client_connection()
      validate_addresses()
      template()

      insert_dictionaries()

      legal_entity_params =
        Map.merge(get_legal_entity_data(), %{
          "type" => @legal_entity_type_pharmacy,
          "kveds" => [@kveds_allowed_pharmacy]
        })

      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_edr_by_code(
        {:ok,
         %{
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"display" => legal_entity_params["name"]},
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})

      resp =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(200)

      assert resp
    end

    test "create legal entity sign edrpou", %{conn: conn} do
      get_client_type_by_name()
      put_client()
      upsert_client_connection()
      validate_addresses()
      template()

      insert_dictionaries()
      legal_entity_type = "MSP"
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => legal_entity_type})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_edr_by_code(
        {:ok,
         %{
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"display" => legal_entity_params["name"]},
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})

      resp =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(200)

      assert resp
    end

    test "create legal entity sign drfo code", %{conn: conn} do
      get_client_type_by_name()
      put_client()
      upsert_client_connection()

      validate_addresses()
      template()

      insert_dictionaries()
      legal_entity_type = "MSP"
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => legal_entity_type, "edrpou" => "123456789"})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      drfo_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_edr_by_passport(
        {:ok,
         %{
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"display" => legal_entity_params["name"]},
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})

      resp =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(200)

      assert resp
    end

    test "create legal entity sign drfo code when edrpou empty string", %{conn: conn} do
      get_client_type_by_name()
      put_client()
      upsert_client_connection()
      validate_addresses()
      template()

      insert_dictionaries()
      legal_entity_type = "MSP"
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => legal_entity_type, "edrpou" => "123456789"})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)

      expect_edr_by_passport(
        {:ok,
         %{
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"display" => legal_entity_params["name"]},
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})

      expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
        {:ok,
         %{
           "data" => %{
             "content" => legal_entity_params,
             "signatures" =>
               Enum.map([legal_entity_params["edrpou"]], fn drfo ->
                 %{"is_valid" => true, "signer" => %{"drfo" => drfo, "edrpou" => ""}}
               end)
           }
         }}
      end)

      resp =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(200)

      assert resp
    end

    test "create legal entity sign drfo code when edrpou nil string", %{conn: conn} do
      get_client_type_by_name()
      put_client()
      upsert_client_connection()

      validate_addresses()
      template()

      insert_dictionaries()
      legal_entity_type = "MSP"
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => legal_entity_type, "edrpou" => "123456789"})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)

      expect_edr_by_passport(
        {:ok,
         %{
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"display" => legal_entity_params["name"]},
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})

      expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
        {:ok,
         %{
           "data" => %{
             "content" => legal_entity_params,
             "signatures" =>
               Enum.map([legal_entity_params["edrpou"]], fn drfo ->
                 %{"is_valid" => true, "signer" => %{"drfo" => drfo, "edrpou" => nil}}
               end)
           }
         }}
      end)

      assert %{"data" => resp_data} =
               conn
               |> put_req_header("content-type", "application/json")
               |> put_req_header("content-length", "7000")
               |> put_req_header("x-consumer-id", UUID.generate())
               |> put_req_header("edrpou", legal_entity_params["edrpou"])
               |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
               |> json_response(200)

      assert %{"nhs_reviewed" => false, "nhs_verified" => false} = resp_data
    end

    test "update legal entity sign drfo code when edrpou nil string", %{conn: conn} do
      %{edrpou: edrpou} = insert(:prm, :legal_entity)

      get_client_type_by_name()
      put_client()
      upsert_client_connection()

      validate_addresses()
      template()

      insert_dictionaries()
      legal_entity_type = "MSP"
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => legal_entity_type, "edrpou" => edrpou})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)

      expect_edr_by_passport(
        {:ok,
         %{
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"display" => legal_entity_params["name"]},
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})

      expect(SignatureMock, :decode_and_validate, fn _, _, _ ->
        {:ok,
         %{
           "data" => %{
             "content" => legal_entity_params,
             "signatures" =>
               Enum.map([legal_entity_params["edrpou"]], fn drfo ->
                 %{"is_valid" => true, "signer" => %{"drfo" => drfo, "edrpou" => nil}}
               end)
           }
         }}
      end)

      assert %{"data" => resp_data} =
               conn
               |> put_req_header("content-type", "application/json")
               |> put_req_header("content-length", "7000")
               |> put_req_header("x-consumer-id", UUID.generate())
               |> put_req_header("edrpou", legal_entity_params["edrpou"])
               |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
               |> json_response(200)

      assert %{"nhs_reviewed" => false, "nhs_verified" => false} = resp_data
    end

    test "fail to create legal entity sign drfo passport number is not allowed", %{conn: conn} do
      insert_dictionaries()
      legal_entity_type = "MSP"
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => legal_entity_type, "edrpou" => "ЯЁ756475"})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      drfo_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      resp =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
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
      legal_entity_type = "MSP"
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => legal_entity_type, "edrpou" => "7564750099"})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      drfo_signed_content(legal_entity_params, "0123456789")

      resp =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
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

      legal_entity_params =
        Map.merge(get_legal_entity_data(), %{
          "type" => @legal_entity_type_pharmacy,
          "kveds" => [@kveds_allowed_pharmacy]
        })

      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_edr_by_code({:error, :timeout})

      resp =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(409)

      assert get_in(resp, ~w(error message)) == "Legal Entity not found in EDR"
    end

    test "fail to create legal entity when EDR API returns response with invalid legal entity status", %{conn: conn} do
      validate_addresses()
      insert_dictionaries()

      legal_entity_params =
        Map.merge(get_legal_entity_data(), %{
          "type" => @legal_entity_type_pharmacy,
          "kveds" => [@kveds_allowed_pharmacy]
        })

      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_edr_by_code({:ok, %{"state" => 0}})

      resp =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(409)

      assert get_in(resp, ~w(error message)) == "Invalid Legal Entity status in EDR"
    end

    test "fail to create legal entity when EDR API returns response with invalid legal entity attrs", %{conn: conn} do
      validate_addresses()
      insert_dictionaries()

      legal_entity_params =
        Map.merge(get_legal_entity_data(), %{
          "type" => @legal_entity_type_pharmacy,
          "kveds" => [@kveds_allowed_pharmacy]
        })

      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_edr_by_code(
        {:ok,
         %{
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"display" => "TEST"},
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      resp =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(409)

      assert get_in(resp, ~w(error message)) == "Provided data doesn't match with EDR data"
    end

    test "fail to create legal entity when EDR API returns response with invalid legal address", %{conn: conn} do
      validate_addresses()
      insert_dictionaries()

      legal_entity_params =
        Map.merge(get_legal_entity_data(), %{
          "type" => @legal_entity_type_pharmacy,
          "kveds" => [@kveds_allowed_pharmacy]
        })

      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_edr_by_code(
        {:ok,
         %{
           "address" => %{"parts" => %{"atu_code" => "6010100000"}},
           "names" => %{"display" => legal_entity_params["name"]},
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})

      resp =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(409)

      assert get_in(resp, ~w(error message)) == "Provided data doesn't match with EDR data"
    end
  end

  describe "contract suspend on update legal entity" do
    test "contract suspend on change legal entity name", %{conn: conn} do
      get_client_type_by_name(2)
      put_client(2)
      upsert_client_connection(2)
      validate_addresses()
      template(2)

      insert_dictionaries()
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => "MSP"})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      consumer_id = UUID.generate()
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_edr_by_code(
        {:ok,
         %{
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"display" => legal_entity_params["name"]},
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})

      resp1 =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", consumer_id)
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(200)

      id = resp1["data"]["id"]
      legal_entity = LegalEntities.get_by_id(id)

      %{id: contract_id} =
        insert(:prm, :capitation_contract, contractor_legal_entity: legal_entity, is_suspended: false)

      %{id: contract_id2} = insert(:prm, :capitation_contract, is_suspended: false)

      legal_entity_params = Map.put(legal_entity_params, "name", "Institute of medical researches ISMT")
      legal_entity_params = Map.put(legal_entity_params, "status", "CLOSED")

      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      validate_addresses()

      expect_edr_by_code(
        {:ok,
         %{
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"display" => legal_entity_params["name"]},
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})

      assert conn
             |> put_req_header("content-type", "application/json")
             |> put_req_header("content-length", "7000")
             |> put_req_header("edrpou", legal_entity_params["edrpou"])
             |> put_consumer_id_header()
             |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
             |> json_response(200)

      contract = PRMRepo.get(CapitationContract, contract_id)
      contract2 = PRMRepo.get(CapitationContract, contract_id2)

      assert contract.is_suspended
      refute contract2.is_suspended
    end

    test "contract suspend on changed legal entity owner", %{conn: conn} do
      get_client_type_by_name()
      put_client()
      upsert_client_connection()
      validate_addresses()
      template(2)
      get_roles_by_name()
      get_user_roles()
      create_user_role()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "email" => "new-owner@example.com",
             "type" => "user"
           }
         }}
      end)

      legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :employee, employee_type: Employee.type(:owner), legal_entity_id: legal_entity.id)

      %{id: contract_id} =
        insert(:prm, :capitation_contract, contractor_legal_entity: legal_entity, is_suspended: false)

      %{id: contract_id2} = insert(:prm, :capitation_contract, is_suspended: false)

      owner = %{
        "birth_date" => "1988-08-19",
        "documents" => [%{"number" => "120518", "type" => "PASSPORT"}],
        "email" => "new-owner@example.com",
        "first_name" => "Олесь",
        "gender" => "MALE",
        "last_name" => "Головко",
        "no_tax_id" => false,
        "phones" => [%{"number" => "+380701112233", "type" => "MOBILE"}],
        "position" => "P1",
        "second_name" => "Миколайович",
        "tax_id" => "3243004010"
      }

      legal_entity_params =
        Map.merge(get_legal_entity_data(), %{
          "edrpou" => legal_entity.edrpou,
          "type" => "MSP",
          "owner" => owner
        })

      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_edr_by_code(
        {:ok,
         %{
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"display" => legal_entity_params["name"]},
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})

      employee_request_id =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put_consumer_id_header()
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(200)
        |> get_in(~w(urgent employee_request_id))

      conn
      |> put_consumer_id_header()
      |> put_client_id_header(legal_entity.id)
      |> post(employee_request_path(conn, :approve, employee_request_id))
      |> json_response(200)

      contract = PRMRepo.get(CapitationContract, contract_id)
      contract2 = PRMRepo.get(CapitationContract, contract_id2)

      assert contract.is_suspended
      refute contract2.is_suspended
    end

    test "contract suspend on change status", %{conn: conn} do
      get_client_type_by_name(2)
      put_client(2)
      upsert_client_connection(2)
      validate_addresses()
      template(2)

      insert_dictionaries()
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => "MSP"})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      consumer_id = UUID.generate()
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_edr_by_code(
        {:ok,
         %{
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"display" => legal_entity_params["name"]},
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})

      resp1 =
        conn
        |> put_req_header("x-consumer-id", consumer_id)
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(200)

      id = resp1["data"]["id"]
      legal_entity = LegalEntities.get_by_id(id)
      %{id: contract_id} = insert(:prm, :capitation_contract, contractor_legal_entity: legal_entity)
      legal_entity_params = Map.put(legal_entity_params, "status", "CLOSED")
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      validate_addresses()

      expect_edr_by_code(
        {:ok,
         %{
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"display" => legal_entity_params["name"]},
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})

      resp2 =
        conn
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(200)

      assert resp2

      contract = PRMRepo.get(CapitationContract, contract_id)
      assert contract.is_suspended
    end

    test "contract suspend on change address", %{conn: conn} do
      get_client_type_by_name(2)
      put_client(2)
      upsert_client_connection(2)
      validate_addresses()
      template(2)

      insert_dictionaries()
      legal_entity_params = Map.merge(get_legal_entity_data(), %{"type" => "MSP"})
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      consumer_id = UUID.generate()
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      expect_edr_by_code(
        {:ok,
         %{
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"display" => legal_entity_params["name"]},
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})

      resp1 =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", consumer_id)
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(200)

      id = resp1["data"]["id"]

      legal_entity = LegalEntities.get_by_id(id)
      %{id: contract_id} = insert(:prm, :capitation_contract, contractor_legal_entity: legal_entity)

      [address | addresses] = legal_entity_params["addresses"]
      addresses = [%{address | "apartment" => "42/12"} | addresses]
      legal_entity_params = Map.put(legal_entity_params, "addresses", addresses)
      legal_entity_params_signed = sign_legal_entity(legal_entity_params)
      edrpou_signed_content(legal_entity_params, legal_entity_params["edrpou"])

      validate_addresses()

      expect_edr_by_code(
        {:ok,
         %{
           "address" => %{"parts" => %{"atu_code" => "6310100000"}},
           "names" => %{"display" => legal_entity_params["name"]},
           "olf_code" => legal_entity_params["legal_form"],
           "state" => 1
         }}
      )

      expect_settlement_by_id({:ok, %{koatuu: "6300000000"}})

      resp2 =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("content-length", "7000")
        |> put_req_header("x-consumer-id", UUID.generate())
        |> put_req_header("edrpou", legal_entity_params["edrpou"])
        |> put(legal_entity_path(conn, :create_or_update), legal_entity_params_signed)
        |> json_response(200)

      assert resp2

      contract = PRMRepo.get(CapitationContract, contract_id)
      assert contract.is_suspended
    end
  end

  describe "verify legal entities" do
    test "mis verify legal entity", %{conn: conn} do
      %{id: id} = insert(:prm, :legal_entity, mis_verified: "NOT_VERIFIED")
      conn = put_client_id_header(conn, id)
      conn = patch(conn, legal_entity_path(conn, :mis_verify, id))
      assert json_response(conn, 200)["data"]["mis_verified"] == "VERIFIED"
    end

    test "mis verify legal entity which was already verified", %{conn: conn} do
      %{id: id} = insert(:prm, :legal_entity, mis_verified: "VERIFIED")
      conn = put_client_id_header(conn, id)
      conn = patch(conn, legal_entity_path(conn, :mis_verify, id))
      assert json_response(conn, 409)
    end

    test "nhs verify legal entity which was already verified", %{conn: conn} do
      %{id: id} = insert(:prm, :legal_entity, nhs_verified: true)
      conn = put_client_id_header(conn, id)
      conn = patch(conn, legal_entity_path(conn, :nhs_verify, id))
      refute json_response(conn, 409)["data"]["nhs_verified"]
    end

    test "nhs verify legal entity", %{conn: conn} do
      %{id: id} = insert(:prm, :legal_entity, nhs_verified: false)
      conn = put_client_id_header(conn, id)
      conn = patch(conn, legal_entity_path(conn, :nhs_verify, id))
      assert json_response(conn, 200)["data"]["nhs_verified"]
    end
  end

  describe "get legal entities" do
    setup %{conn: conn} do
      insert(:prm, :legal_entity)
      insert(:prm, :legal_entity)
      %{conn: conn}
    end

    test "without x-consumer-metadata", %{conn: conn} do
      conn = get(conn, legal_entity_path(conn, :index, edrpou: "37367387"))
      assert 401 == json_response(conn, 401)["meta"]["code"]
    end

    test "with x-consumer-metadata that contains MIS client_id", %{conn: conn} do
      msp()
      %{id: id, edrpou: edrpou} = insert(:prm, :legal_entity)

      resp =
        conn
        |> put_client_id_header(id)
        |> get(legal_entity_path(conn, :index, edrpou: edrpou))
        |> json_response(200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert_list_response_schema(resp["data"], "legal_entity")

      Enum.each(resp["data"], fn resp_entity ->
        assert %{"mis_verified" => _, "nhs_verified" => _, "nhs_reviewed" => _} = resp_entity
      end)

      assert_list_response_schema(resp["data"], "legal_entity")
      assert 1 == length(resp["data"])
    end

    test "with x-consumer-metadata that contains NHS client_id", %{conn: conn} do
      nhs()
      %{id: id, edrpou: edrpou} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get(conn, legal_entity_path(conn, :index, edrpou: edrpou))
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
      conn = get(conn, legal_entity_path(conn, :index))
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
      conn = get(conn, legal_entity_path(conn, :index, type: LegalEntity.type(:msp)))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
      assert id == hd(resp["data"])["id"]
    end

    test "search by type pharmacy", %{conn: conn} do
      msp()
      %{id: id} = insert(:prm, :legal_entity, type: LegalEntity.type(:pharmacy))
      conn = put_client_id_header(conn, id)
      conn = get(conn, legal_entity_path(conn, :index, type: LegalEntity.type(:pharmacy)))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
      assert id == hd(resp["data"])["id"]
    end

    test "search by type status and settlement_id", %{conn: conn} do
      msp()
      settlement_id = Ecto.UUID.generate()

      %{id: id} =
        insert(
          :prm,
          :legal_entity,
          status: LegalEntity.status(:active),
          addresses: [
            %{settlement_id: settlement_id}
          ]
        )

      conn = put_client_id_header(conn, id)
      conn = get(conn, legal_entity_path(conn, :index, status: "ACTIVE", settlement_id: settlement_id))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert is_list(resp["data"])
      assert 1 == length(resp["data"])
      assert id == hd(resp["data"])["id"]
    end

    test "with x-consumer-metadata that contains client_id that does not match legal entity id", %{conn: conn} do
      msp()
      conn = put_client_id_header(conn, Ecto.UUID.generate())
      id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = get(conn, legal_entity_path(conn, :index, legal_entity_id: id))
      resp = json_response(conn, 200)
      assert [] == resp["data"]
      assert Map.has_key?(resp, "paging")
      assert String.contains?(resp["meta"]["url"], "/legal_entities")
    end

    test "with client_id that does not exists", %{conn: conn} do
      expect(MithrilMock, :get_client_type_name, fn _, _ -> {:error, :access_denied} end)
      conn = put_client_id_header(conn, UUID.generate())
      id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = get(conn, legal_entity_path(conn, :index, legal_entity_id: id))
      json_response(conn, 401)
    end
  end

  describe "get legal entity by id" do
    test "without x-consumer-metadata", %{conn: conn} do
      id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = get(conn, legal_entity_path(conn, :show, id))
      json_response(conn, 401)
    end

    test "with x-consumer-metadata that contains client_id that does not match legal entity id", %{conn: conn} do
      msp()
      conn = put_client_id_header(conn, Ecto.UUID.generate())
      %{id: id} = insert(:prm, :legal_entity)
      conn = get(conn, legal_entity_path(conn, :show, id))
      json_response(conn, 403)
    end

    test "with x-consumer-metadata that contains invalid client_type_name", %{conn: conn} do
      expect(MithrilMock, :get_client_type_name, fn _, _ -> {:ok, nil} end)
      conn = put_client_id_header(conn, UUID.generate())
      id = "7cc91a5d-c02f-41e9-b571-1ea4f2375552"
      conn = get(conn, legal_entity_path(conn, :show, id))
      json_response(conn, 403)
    end

    test "check required legal entity fields", %{conn: conn} do
      msp()
      %{id: id} = insert(:prm, :legal_entity)

      resp =
        conn
        |> put_client_id_header(id)
        |> get(legal_entity_path(conn, :show, id))
        |> json_response(200)

      assert match?(%{"mis_verified" => "VERIFIED", "nhs_reviewed" => _}, resp["data"])
      refute resp["data"]["nhs_verified"]
    end

    test "with x-consumer-metadata that contains client_id that matches legal entity id", %{conn: conn} do
      msp()
      %{id: id} = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, id)
      conn = get(conn, legal_entity_path(conn, :show, id))
      resp = json_response(conn, 200)

      assert id == resp["data"]["id"]
      assert Map.has_key?(resp["data"], "medical_service_provider")
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
      conn = get(conn, legal_entity_path(conn, :show, id))
      resp = json_response(conn, 200)

      assert id == resp["data"]["id"]
      assert Map.has_key?(resp["data"], "medical_service_provider")
      refute Map.has_key?(resp, "paging")
    end

    test "with x-consumer-metadata that contains client_id that matches inactive legal entity id", %{conn: conn} do
      msp()
      %{id: id} = insert(:prm, :legal_entity, is_active: false)
      conn = put_client_id_header(conn, id)
      conn = get(conn, legal_entity_path(conn, :show, id))
      assert 404 == json_response(conn, 404)["meta"]["code"]
    end

    test "with client_id that does not exists", %{conn: conn} do
      expect(MithrilMock, :get_client_type_name, fn _, _ -> {:error, :access_denied} end)
      conn = put_client_id_header(conn, UUID.generate())
      conn = get(conn, legal_entity_path(conn, :show, UUID.generate()))
      json_response(conn, 401)
    end
  end

  describe "get related legal_entities" do
    test "invalid client_id", %{conn: conn} do
      from_legal_entity = insert(:prm, :legal_entity)
      to_legal_entity = insert(:prm, :legal_entity)

      resp =
        conn
        |> put_client_id_header(to_legal_entity.id)
        |> get(legal_entity_path(conn, :list_legators, from_legal_entity.id))
        |> json_response(403)

      assert %{"error" => %{"message" => "User is not allowed to view"}} = resp
    end

    test "success", %{conn: conn} do
      from_legal_entity = insert(:prm, :legal_entity)
      to_legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :related_legal_entity, merged_from: to_legal_entity, merged_to: from_legal_entity)

      resp =
        conn
        |> put_client_id_header(from_legal_entity.id)
        |> get(legal_entity_path(conn, :list_legators, from_legal_entity.id))
        |> json_response(200)

      assert_list_response_schema(resp["data"], "related_legal_entity")
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
    "../core/test/data/legal_entity.json"
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
