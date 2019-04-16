defmodule EHealth.Web.Cabinet.PersonsControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import Core.Expectations.Signature
  import Mox

  alias Ecto.UUID

  setup :verify_on_exit!

  describe "update person" do
    setup conn_data do
      tax_id = "2222222225"

      emergency_contact = %{
        "first_name" => "Петро",
        "last_name" => "Іванов",
        "second_name" => "Миколайович"
      }

      documents = [
        %{
          "type" => "PASSPORT",
          "number" => "ФШ543210",
          "issued_by" => "Рокитнянським РВ ГУ МВС Київської області",
          "issued_at" => "2017-02-28"
        }
      ]

      data =
        :person
        |> build(
          addresses: [build(:address)],
          tax_id: tax_id,
          emergency_contact: emergency_contact,
          documents: documents,
          birth_date: "1990-01-01",
          unzr: nil
        )
        |> Poison.encode!()
        |> Poison.decode!()
        |> Map.drop(~w(unzr version updated_by updated_at patient_signed master_persons
          merged_persons invalid_tax_id inserted_by inserted_at status is_active id death_date no_tax_id))

      conn_data
      |> Map.put(:data, data)
      |> Map.put(:tax_id, tax_id)
    end

    test "no required header", %{conn: conn} do
      resp =
        conn
        |> patch(cabinet_persons_path(conn, :update_person, UUID.generate()))
        |> json_response(401)

      assert %{"error" => %{"type" => "access_denied", "message" => "Missing header x-consumer-metadata"}} = resp
    end

    test "invalid params", %{conn: conn, tax_id: tax_id} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c",
             "tax_id" => tax_id
           }
         }}
      end)

      legal_entity = insert(:prm, :legal_entity)

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      resp =
        conn
        |> patch(cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"))
        |> json_response(422)

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

    test "invalid signed content", %{conn: conn, tax_id: tax_id} do
      cabinet()
      legal_entity = insert(:prm, :legal_entity)

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c",
             "tax_id" => tax_id
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

    test "tax_id doesn't match with signed content", %{conn: conn, tax_id: tax_id} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c",
             "tax_id" => tax_id
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [person_id] ->
        {:ok, build(:person, id: person_id, tax_id: "3378115538")}
      end)

      drfo_signed_content(%{}, "3378115538")
      legal_entity = insert(:prm, :legal_entity)
      party = insert(:prm, :party)
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      resp =
        conn
        |> patch(cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Jason.encode!(%{}))
        })
        |> json_response(422)

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

    test "tax_id doesn't match with signer", %{conn: conn, tax_id: tax_id} do
      cabinet()
      person_id = UUID.generate()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id,
             "tax_id" => tax_id
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [^person_id] ->
        {:ok, build(:person, id: person_id, tax_id: "2222222220")}
      end)

      drfo_signed_content(%{"tax_id" => "2222222220"}, "2222222220")
      legal_entity = insert(:prm, :legal_entity)
      party = insert(:prm, :party)
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      resp =
        conn
        |> patch(cabinet_persons_path(conn, :update_person, person_id), %{
          "signed_content" => Base.encode64(Jason.encode!(%{"tax_id" => "2222222220"}))
        })
        |> json_response(422)

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

    test "invalid signed content changeset", %{conn: conn, tax_id: tax_id} do
      cabinet()
      person_id = UUID.generate()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id,
             "tax_id" => tax_id
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [^person_id] ->
        {:ok, build(:person, id: person_id, tax_id: "2222222220")}
      end)

      legal_entity = insert(:prm, :legal_entity)
      party = insert(:prm, :party, tax_id: tax_id)
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")
      drfo_signed_content(%{"tax_id" => tax_id}, tax_id)

      conn =
        conn
        |> put_req_header("drfo", tax_id)
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_persons_path(conn, :update_person, person_id), %{
          "signed_content" => Base.encode64(Jason.encode!(%{"tax_id" => tax_id}))
        })

      assert json_response(conn, 422)
    end

    test "user person_id doesn't match query param id", %{conn: conn, tax_id: tax_id} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok, %{"data" => %{"id" => id, "person_id" => UUID.generate(), "tax_id" => tax_id}}}
      end)

      legal_entity = insert(:prm, :legal_entity)

      conn =
        conn
        |> put_req_header("x-consumer-id", "668d1541-e4cf-4a95-a25a-60d83864ceaf")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn =
        patch(conn, cabinet_persons_path(conn, :update_person, UUID.generate()), %{
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

      conn = patch(conn, cabinet_persons_path(conn, :update_person, UUID.generate()), %{})
      assert json_response(conn, 403)
    end

    test "success update person", %{conn: conn, data: data} do
      cabinet()
      person_id = UUID.generate()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [^person_id] ->
        {:ok, build(:person, id: person_id, tax_id: data["tax_id"])}
      end)

      expect(OTPVerificationMock, :search, fn _, _ ->
        {:ok, %{"data" => []}}
      end)

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok, %{"data" => %{"id" => id, "person_id" => person_id, "tax_id" => data["tax_id"]}}}
      end)

      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      party = insert(:prm, :party, tax_id: data["tax_id"])
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      expect(MPIMock, :update_person, fn id, _params, _headers ->
        get_person(id, 200, %{documents: get_person_documents(), addresses: get_person_addresses()})
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      conn =
        conn
        |> put_req_header("drfo", data["tax_id"])
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      expect_uaddresses_validate()
      drfo_signed_content(data, data["tax_id"])

      assert conn
             |> patch(cabinet_persons_path(conn, :update_person, person_id), %{
               "signed_content" => Base.encode64(Jason.encode!(data))
             })
             |> json_response(200)
    end

    test "update person with valid unzr", %{conn: conn, data: data} do
      cabinet()

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [id] ->
        {:ok, build(:person, id: id, tax_id: data["tax_id"])}
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
             "tax_id" => data["tax_id"]
           }
         }}
      end)

      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      party = insert(:prm, :party, tax_id: data["tax_id"])
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      conn =
        conn
        |> put_req_header("drfo", data["tax_id"])
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      expect_uaddresses_validate()

      unzr = "#{String.replace(data["birth_date"], "-", "")}-01234"
      data = Map.put(data, "unzr", unzr)

      expect(MPIMock, :update_person, fn id, _params, _headers ->
        get_person(id, 200, %{addresses: get_person_addresses(), unzr: unzr})
      end)

      drfo_signed_content(data, data["tax_id"])

      resp =
        conn
        |> patch(cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Jason.encode!(data))
        })
        |> json_response(200)

      assert resp["data"]["unzr"] == unzr
    end

    test "validation unzr works", %{conn: conn, data: data} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c",
             "tax_id" => data["tax_id"]
           }
         }}
      end)

      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      party = insert(:prm, :party, tax_id: data["tax_id"])
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      conn =
        conn
        |> put_req_header("drfo", data["tax_id"])
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      unzr = "20180925-01234"
      data = Map.put(data, "unzr", unzr)

      drfo_signed_content(data, data["tax_id"])

      resp =
        conn
        |> patch(cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Jason.encode!(data))
        })
        |> json_response(422)

      assert [
               %{
                 "entry" => "$.person.unzr",
                 "rules" => [
                   %{"description" => "Birthdate or unzr is not correct", "params" => ["unzr"], "rule" => "invalid"}
                 ]
               }
             ] = resp["error"]["invalid"]
    end

    test "validation person passports works", %{conn: conn, data: data} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c",
             "tax_id" => data["tax_id"]
           }
         }}
      end)

      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      party = insert(:prm, :party, tax_id: data["tax_id"])
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      conn =
        conn
        |> put_req_header("drfo", data["tax_id"])
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      unzr = "#{String.replace(data["birth_date"], "-", "")}-01234"

      data =
        data
        |> Map.put("unzr", unzr)
        |> Map.put("documents", [
          %{
            "issued_at" => "2017-02-28",
            "issued_by" => "Рокитнянським РВ ГУ МВС Київської області",
            "number" => "012345678",
            "type" => "NATIONAL_ID"
          }
          | data["documents"]
        ])

      drfo_signed_content(data, data["tax_id"])

      resp =
        conn
        |> patch(cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Jason.encode!(data))
        })
        |> json_response(422)

      assert [
               %{
                 "entry" => "$.person.documents",
                 "rules" => [
                   %{
                     "description" => "Person can have only new passport NATIONAL_ID or old PASSPORT",
                     "params" => ["$.person.documents"]
                   }
                 ]
               }
             ] = resp["error"]["invalid"]
    end

    test "validation unzr exists if document NATIONAL_ID provided", %{conn: conn, data: data} do
      cabinet()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => "c8912855-21c3-4771-ba18-bcd8e524f14c",
             "tax_id" => data["tax_id"]
           }
         }}
      end)

      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      party = insert(:prm, :party, tax_id: data["tax_id"])
      insert(:prm, :party_user, party: party, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      conn =
        conn
        |> put_req_header("drfo", data["tax_id"])
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      data =
        data
        |> Map.put("documents", [
          %{
            "issued_at" => "2017-02-28",
            "issued_by" => "Рокитнянським РВ ГУ МВС Київської області",
            "number" => "012345678",
            "type" => "NATIONAL_ID"
          }
        ])

      drfo_signed_content(data, data["tax_id"])

      resp =
        conn
        |> patch(cabinet_persons_path(conn, :update_person, "c8912855-21c3-4771-ba18-bcd8e524f14c"), %{
          "signed_content" => Base.encode64(Jason.encode!(data))
        })
        |> json_response(422)

      assert [
               %{
                 "entry" => "$.person",
                 "rules" => [
                   %{
                     "description" => "unzr is mandatory for document type NATIONAL_ID",
                     "params" => ["unzr"]
                   }
                 ]
               }
             ] = resp["error"]["invalid"]
    end
  end

  describe "get person details" do
    setup conn_data do
      Map.put(conn_data, :tax_id, "2222222225")
    end

    test "no required header", %{conn: conn} do
      resp =
        conn
        |> get(cabinet_persons_path(conn, :personal_info))
        |> json_response(401)

      assert %{"error" => %{"type" => "access_denied", "message" => "Missing header x-consumer-metadata"}} = resp
    end

    test "tax_id are different in user and person", %{conn: conn, tax_id: tax_id} do
      cabinet()
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      person_id = UUID.generate()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id,
             "tax_id" => tax_id
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [^person_id] ->
        {:ok,
         build(:person,
           id: person_id,
           first_name: "Алекс",
           last_name: "Джонс",
           second_name: "Петрович",
           tax_id: "2222222220"
         )}
      end)

      resp =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))
        |> get(cabinet_persons_path(conn, :personal_info))
        |> json_response(401)

      assert %{"error" => %{"type" => "access_denied", "message" => "Person not found"}} = resp
    end

    test "returns person detail for logged user", %{conn: conn, tax_id: tax_id} do
      cabinet()
      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      person_id = UUID.generate()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id,
             "tax_id" => tax_id,
             "is_blocked" => false
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [^person_id] ->
        {:ok,
         build(:person, id: person_id, first_name: "Алекс", last_name: "Джонс", second_name: "Петрович", tax_id: tax_id)}
      end)

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      conn = get(conn, cabinet_persons_path(conn, :personal_info))
      response_data = json_response(conn, 200)["data"]

      assert person_id == response_data["id"]
      assert "Алекс" == response_data["first_name"]
      assert "Джонс" == response_data["last_name"]
      assert "Петрович" == response_data["second_name"]
    end
  end

  describe "person details" do
    setup conn_data do
      Map.put(conn_data, :tax_id, "2222222225")
    end

    test "no required header", %{conn: conn} do
      resp =
        conn
        |> get(cabinet_persons_path(conn, :person_details))
        |> json_response(401)

      assert %{"error" => %{"type" => "access_denied", "message" => "Missing header x-consumer-metadata"}} = resp
    end

    test "tax_id are different in user and person", %{conn: conn, tax_id: tax_id} do
      cabinet()
      person_id = UUID.generate()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id,
             "tax_id" => tax_id
           }
         }}
      end)

      legal_entity = insert(:prm, :legal_entity, id: "c3cc1def-48b6-4451-be9d-3b777ef06ff9")
      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [^person_id] ->
        {:ok,
         build(:person,
           id: person_id,
           first_name: "Алекс",
           second_name: "Петрович",
           birth_country: "string value",
           birth_settlement: "string value",
           gender: "string value",
           email: "test@example.com",
           tax_id: "2222222220",
           documents: [%{type: "BIRTH_CERTIFICATE", number: "1234567890"}],
           phones: [%{type: "MOBILE", number: "+380972526080"}],
           secret: "string value",
           emergency_contact: %{},
           process_disclosure_data_consent: true,
           authentication_methods: [%{"type" => "NA"}],
           preferred_way_communication: "––"
         )}
      end)

      conn =
        conn
        |> put_req_header("x-consumer-id", "8069cb5c-3156-410b-9039-a1b2f2a4136c")
        |> put_req_header("x-consumer-metadata", Jason.encode!(%{client_id: legal_entity.id}))

      resp =
        conn
        |> get(cabinet_persons_path(conn, :person_details))
        |> json_response(401)

      assert %{"error" => %{"type" => "access_denied", "message" => "Person not found"}} = resp
    end

    test "success get person details", %{conn: conn, tax_id: tax_id} do
      cabinet()
      legal_entity = insert(:prm, :legal_entity)
      insert(:prm, :party_user, user_id: "8069cb5c-3156-410b-9039-a1b2f2a4136c")
      person_id = UUID.generate()

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        {:ok,
         %{
           "data" => %{
             "id" => id,
             "person_id" => person_id,
             "tax_id" => tax_id
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn "mpi", MPI.Rpc, :get_person_by_id, [^person_id] ->
        {:ok,
         build(:person,
           id: person_id,
           first_name: "Алекс",
           second_name: "Петрович",
           birth_country: "string value",
           birth_settlement: "string value",
           gender: "string value",
           email: "test@example.com",
           tax_id: tax_id,
           unzr: "20180925-012345",
           documents: [
             %{
               type: "BIRTH_CERTIFICATE",
               number: "1234567890",
               expiration_date: "2024-02-12"
             }
           ],
           phones: [%{type: "MOBILE", number: "+380972526080"}],
           secret: "string value",
           emergency_contact: %{},
           process_disclosure_data_consent: true,
           authentication_methods: [%{"type" => "NA"}],
           preferred_way_communication: "––",
           addresses: rpc_maps(get_person_addresses())
         )}
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

      assert data["id"] == person_id
      assert data["first_name"] == "Алекс"
      assert data["second_name"] == "Петрович"
      assert Regex.match?(~r/^\d{4}-\d{2}-\d{2}$/, data["birth_date"])
      assert data["birth_country"] == "string value"
      assert data["birth_settlement"] == "string value"
      assert data["gender"] == "string value"
      assert data["email"] == "test@example.com"
      assert data["tax_id"] == tax_id
      assert data["unzr"] == "20180925-012345"

      assert [
               %{"type" => "BIRTH_CERTIFICATE", "number" => "1234567890", "expiration_date" => "2024-02-12"}
             ] == data["documents"]

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

  defp get_person_documents do
    [
      %{
        "type" => "BIRTH_CERTIFICATE",
        "number" => "1234567890",
        "issued_at" => "2014-02-12",
        "expiration_date" => "2024-02-12"
      }
    ]
  end

  defp rpc_maps(maps) do
    Enum.map(maps, &Map.new(&1, fn {k, v} -> {String.to_atom(k), v} end))
  end
end
