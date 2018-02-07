defmodule EHealth.Web.DeclarationRequestControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import EHealth.SimpleFactory

  alias Ecto.UUID
  alias EHealth.DeclarationRequest

  describe "list declaration requests" do
    test "no legal_entity_id match", %{conn: conn} do
      legal_entity_id = UUID.generate()

      Enum.map(1..2, fn _ ->
        fixture(DeclarationRequest, fixture_params())
      end)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, declaration_request_path(conn, :index))
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp)
    end

    test "match by legal_entity_id", %{conn: conn} do
      legal_entity_id = UUID.generate()
      employee_id = UUID.generate()

      Enum.map(1..2, fn _ ->
        params =
          fixture_params()
          |> put_in([:data, :employee, :id], employee_id)
          |> put_in([:data, :legal_entity, :id], legal_entity_id)

        fixture(DeclarationRequest, params)
      end)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, declaration_request_path(conn, :index))
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp, 2)
    end

    test "no employee_id match", %{conn: conn} do
      legal_entity_id = UUID.generate()
      employee_id = UUID.generate()

      Enum.map(1..2, fn _ ->
        params =
          fixture_params()
          |> put_in([:data, :legal_entity, :id], legal_entity_id)

        fixture(DeclarationRequest, params)
      end)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, declaration_request_path(conn, :index, %{employee_id: employee_id}))
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp)
    end

    test "match by employee_id", %{conn: conn} do
      legal_entity_id = UUID.generate()
      employee_id = UUID.generate()

      Enum.map(1..2, fn _ ->
        params =
          fixture_params()
          |> put_in([:data, :legal_entity, :id], legal_entity_id)
          |> put_in([:data, :employee, :id], employee_id)

        fixture(DeclarationRequest, params)
      end)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, declaration_request_path(conn, :index, %{employee_id: employee_id}))
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp, 2)
    end

    test "no status match", %{conn: conn} do
      legal_entity_id = UUID.generate()

      Enum.map(1..2, fn _ ->
        params =
          fixture_params()
          |> put_in([:data, :legal_entity, :id], legal_entity_id)

        fixture(DeclarationRequest, params)
      end)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, declaration_request_path(conn, :index, %{status: "ACTIVE"}))
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp)
    end

    test "match by status", %{conn: conn} do
      legal_entity_id = UUID.generate()
      status = "ACTIVE"

      Enum.map(1..2, fn _ ->
        params =
          fixture_params()
          |> put_in([:data, :legal_entity, :id], legal_entity_id)
          |> put_in([:status], status)

        fixture(DeclarationRequest, params)
      end)

      conn = put_client_id_header(conn, legal_entity_id)
      conn = get(conn, declaration_request_path(conn, :index, %{status: status}))
      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp, 2)
    end

    test "match by legal_entity_id, employee_id, status", %{conn: conn} do
      legal_entity_id = UUID.generate()
      employee_id = UUID.generate()
      status = "ACTIVE"

      Enum.map(1..2, fn _ ->
        params =
          fixture_params()
          |> put_in([:data, :legal_entity, :id], legal_entity_id)
          |> put_in([:data, :employee, :id], employee_id)
          |> put_in([:status], status)

        fixture(DeclarationRequest, params)
      end)

      conn = put_client_id_header(conn, legal_entity_id)

      conn =
        get(
          conn,
          declaration_request_path(conn, :index, %{
            status: status,
            employee_id: employee_id
          })
        )

      resp = json_response(conn, 200)

      assert_count_declaration_request_list(resp, 2)
    end
  end

  describe "approve declaration_request" do
    defmodule ApproveDeclarationRequest do
      use MicroservicesHelper

      Plug.Router.get "/good_upload" do
        Plug.Conn.send_resp(conn, 200, "")
      end

      Plug.Router.post "/media_content_storage_secrets" do
        [{"port", port}] = :ets.lookup(:uploaded_at_port, "port")

        resp = %{
          data: %{
            secret_url: "http://localhost:#{port}/good_upload"
          }
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(resp))
      end
    end

    setup %{conn: _conn} do
      {:ok, port, ref} = start_microservices(ApproveDeclarationRequest)
      :ets.new(:uploaded_at_port, [:named_table])
      :ets.insert(:uploaded_at_port, {"port", port})
      System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{port: port}}
    end

    test "approve NEW declaration_request", %{conn: conn} do
      declaration_request = insert(:il, :declaration_request, documents: [%{"type" => "ok", "verb" => "HEAD"}])

      conn = put_client_id_header(conn, "356b4182-f9ce-4eda-b6af-43d2de8602f2")
      conn = patch(conn, declaration_request_path(conn, :approve, declaration_request))

      resp = json_response(conn, 200)
      assert DeclarationRequest.status(:approved) == resp["data"]["status"]
    end

    test "approve APPROVED declaration_request", %{conn: conn} do
      params = Map.put(fixture_params(), :status, DeclarationRequest.status(:approved))
      declaration_request = fixture(DeclarationRequest, params)

      conn = put_client_id_header(conn, "356b4182-f9ce-4eda-b6af-43d2de8602f2")
      conn = patch(conn, declaration_request_path(conn, :approve, declaration_request))

      resp = json_response(conn, 409)
      assert "Invalid transition" == get_in(resp, ["error", "message"])
    end
  end

  describe "approve declaration request without documents" do
    defmodule ApproveDeclarationRequestNoDocs do
      use MicroservicesHelper

      Plug.Router.get "/no_upload" do
        Plug.Conn.send_resp(conn, 404, "")
      end

      Plug.Router.post "/media_content_storage_secrets" do
        [{"port", port}] = :ets.lookup(:uploaded_at_port, "port")

        resp = %{
          data: %{
            secret_url: "http://localhost:#{port}/no_upload"
          }
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(resp))
      end
    end

    setup %{conn: _conn} do
      {:ok, port, ref} = start_microservices(ApproveDeclarationRequestNoDocs)
      :ets.new(:uploaded_at_port, [:named_table])
      :ets.insert(:uploaded_at_port, {"port", port})
      System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      {:ok, %{port: port}}
    end

    test "approve NEW declaration_request with OFFLINE authentication method", %{conn: conn} do
      declaration_request =
        insert(
          :il,
          :declaration_request,
          authentication_method_current: %{
            "type" => "OFFLINE"
          },
          documents: [
            %{"type" => "ok", "verb" => "HEAD"},
            %{"type" => "empty", "verb" => "HEAD"},
            %{"type" => "person.DECLARATION_FORM", "verb" => "HEAD"}
          ]
        )

      resp =
        conn
        |> put_client_id_header("356b4182-f9ce-4eda-b6af-43d2de8602f2")
        |> patch(declaration_request_path(conn, :approve, declaration_request))
        |> json_response(409)

      assert "Documents ok, empty, person.DECLARATION_FORM is not uploaded" == resp["error"]["message"]
    end
  end

  describe "get declaration request by id" do
    defmodule DynamicSeedValue do
      use MicroservicesHelper

      Plug.Router.get "/latest_block" do
        block = %{
          "block_start" => "some_time",
          "block_end" => "some_time",
          "hash" => "some_hash",
          "inserted_at" => "some_time"
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{data: block}))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(DynamicSeedValue)
      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)
    end

    test "get declaration request by invalid id", %{conn: conn} do
      conn = put_client_id_header(conn, "356b4182-f9ce-4eda-b6af-43d2de8602f2")

      assert_raise Ecto.NoResultsError, fn ->
        get(conn, declaration_request_path(conn, :show, UUID.generate()))
      end
    end

    test "get declaration request by invalid legal_entity_id", %{conn: conn} do
      %{id: id} = fixture(DeclarationRequest, fixture_params())
      conn = put_client_id_header(conn, UUID.generate())

      assert_raise Ecto.NoResultsError, fn ->
        get(conn, declaration_request_path(conn, :show, id))
      end
    end

    test "get declaration request by id", %{conn: conn} do
      %{id: id, data: data} = fixture(DeclarationRequest, fixture_params())
      conn = put_client_id_header(conn, get_in(data, [:legal_entity, :id]))
      conn = get(conn, declaration_request_path(conn, :show, id))
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "urgent")
      assert "some_hash" == get_in(resp, ["data", "seed"])
    end
  end

  describe "resend otp" do
    defmodule OTPVerificationMock do
      use MicroservicesHelper

      Plug.Router.post "/verifications" do
        send_resp(conn, 200, Poison.encode!(%{status: "NEW"}))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(OTPVerificationMock)

      System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      :ok
    end

    test "when declaration request id is invalid", %{conn: conn} do
      conn = put_client_id_header(conn, UUID.generate())

      assert_raise Ecto.NoResultsError, fn ->
        post(conn, declaration_request_path(conn, :resend_otp, UUID.generate()))
      end
    end

    test "when declaration request status is not NEW", %{conn: conn} do
      conn = put_client_id_header(conn, UUID.generate())

      params =
        fixture_params()
        |> Map.put(:status, "APPROVED")

      %{id: id} = fixture(DeclarationRequest, params)

      conn = post(conn, declaration_request_path(conn, :resend_otp, id))
      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      error = resp["error"]
      assert Map.has_key?(error, "invalid")
      assert 1 == length(error["invalid"])
      invalid = Enum.at(error["invalid"], 0)
      assert "$.status" == invalid["entry"]
      assert 1 == length(invalid["rules"])
      rule = Enum.at(invalid["rules"], 0)
      assert "incorrect status" == rule["description"]
    end

    test "when declaration request auth method is not OTP", %{conn: conn} do
      conn = put_client_id_header(conn, UUID.generate())

      params =
        fixture_params()
        |> Map.put(:authentication_method_current, %{type: "OFFLINE"})

      %{id: id} = fixture(DeclarationRequest, params)

      conn = post(conn, declaration_request_path(conn, :resend_otp, id))
      resp = json_response(conn, 422)
      assert Map.has_key?(resp, "error")
      error = resp["error"]
      assert Map.has_key?(error, "invalid")
      assert 1 == length(error["invalid"])
      invalid = Enum.at(error["invalid"], 0)
      assert "$.authentication_method_current" == invalid["entry"]
      assert 1 == length(invalid["rules"])
      rule = Enum.at(invalid["rules"], 0)
      assert "Auth method is not OTP" == rule["description"]
    end

    test "when declaration request fields are correct", %{conn: conn} do
      conn = put_client_id_header(conn, UUID.generate())

      params =
        fixture_params()
        |> Map.put(:authentication_method_current, %{type: "OTP", number: 111})

      %{id: id} = fixture(DeclarationRequest, params)

      conn = post(conn, declaration_request_path(conn, :resend_otp, id))
      resp = json_response(conn, 200)
      assert Map.has_key?(resp, "data")
      assert %{"status" => "NEW"} == resp["data"]
    end
  end

  describe "get documents" do
    defmodule MediaContentStorageMock do
      use MicroservicesHelper

      Plug.Router.post "/media_content_storage_secrets" do
        params = conn.body_params["secret"]

        data = %{
          data: %{
            secret_url: "http://a.link.for/#{params["resource_id"]}/#{params["resource_name"]}"
          }
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(data))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(MediaContentStorageMock)

      System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      :ok
    end

    test "when declaration id is invalid", %{conn: conn} do
      assert_raise Ecto.NoResultsError, fn ->
        get(conn, declaration_request_path(conn, :documents, UUID.generate()))
      end
    end

    test "when declaration id is valid", %{conn: conn} do
      %{id: id, declaration_id: declaration_id} = fixture(DeclarationRequest, fixture_params())

      conn = get(conn, declaration_request_path(conn, :documents, declaration_id))
      result = json_response(conn, 200)["data"]

      expected_result = [
        %{
          "type" => "person.PASSPORT",
          "url" => "http://a.link.for/#{id}/declaration_request_person.PASSPORT.jpeg"
        },
        %{
          "type" => "person.DECLARATION_FORM",
          "url" => "http://a.link.for/#{id}/declaration_request_person.DECLARATION_FORM.jpeg"
        },
        %{
          "type" => "confidant_person.0.PRIMARY.RELATIONSHIP.COURT_DECISION",
          "url" =>
            "http://a.link.for/#{id}/declaration_request_confidant_person.0.PRIMARY.RELATIONSHIP.COURT_DECISION.jpeg"
        }
      ]

      assert expected_result == result
    end
  end

  describe "sign declaration request" do
    test "success", %{conn: conn} do
      data =
        "test/data/declaration_request/sign_request.json"
        |> File.read!()
        |> Poison.decode!()

      tax_id = get_in(data, ~w(employee party tax_id))
      employee_id = get_in(data, ~w(employee id))

      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      insert(:prm, :employee, id: employee_id, legal_entity_id: legal_entity_id)
      %{user_id: user_id} = insert(:prm, :party_user, party: build(:party, tax_id: tax_id))

      %{id: declaration_id} =
        insert(
          :il,
          :declaration_request,
          id: data["id"],
          status: DeclarationRequest.status(:approved),
          data: %{
            "person" => get_person(),
            "declaration_id" => data["declaration_id"],
            "division" => data["division"],
            "employee" => data["employee"],
            "end_date" => data["end_date"],
            "scope" => data["scope"],
            "start_date" => data["start_date"],
            "legal_entity" => data["legal_entity"]
          },
          printout_content: data["content"],
          authentication_method_current: %{"type" => DeclarationRequest.authentication_method(:na)}
        )

      signed_declaration_request =
        data
        |> Map.put("seed", "some_current_hash")
        |> Poison.encode!()
        |> Base.encode64()

      conn
      |> Plug.Conn.put_req_header("drfo", tax_id)
      |> put_client_id_header(legal_entity_id)
      |> put_consumer_id_header(user_id)
      |> patch(declaration_request_path(conn, :sign, declaration_id), %{
        "signed_declaration_request" => signed_declaration_request,
        "signed_content_encoding" => "base64"
      })
      |> json_response(200)
    end

    test "invalid request", %{conn: conn} do
      data =
        "test/data/declaration_request/sign_request.json"
        |> File.read!()
        |> Poison.decode!()

      %{id: legal_entity_id} = insert(:prm, :legal_entity)
      %{id: declaration_id} = insert(:il, :declaration_request)

      assert [err1, err2] =
               conn
               |> put_client_id_header(legal_entity_id)
               |> patch(declaration_request_path(conn, :sign, declaration_id), %{
                 "data" => %{
                   "signed_declaration_request" => data,
                   "signed_content_encoding" => "base64"
                 }
               })
               |> json_response(422)
               |> get_in(["error", "invalid"])

      assert "$.signed_content_encoding" == err1["entry"]
      assert "$.signed_declaration_request" == err2["entry"]
    end
  end

  defp fixture_params do
    uuid = UUID.generate()

    %{
      data: %{
        id: UUID.generate(),
        start_date: "2017-03-02",
        end_date: "2017-03-02",
        person: %{
          id: UUID.generate(),
          first_name: "Петро",
          last_name: "Іванов",
          second_name: "Миколайович",
          documents: [
            %{
              type: "PASSPORT",
              number: "120518"
            }
          ],
          confidant_person: [
            %{
              relation_type: "PRIMARY",
              first_name: "Іван",
              last_name: "Петров",
              second_name: "Миколайович",
              birth_date: "1991-08-20",
              birth_country: "Україна",
              birth_settlement: "Вінниця",
              gender: "MALE",
              tax_id: "2222222225",
              documents_person: [
                %{
                  type: "PASSPORT",
                  number: "120518"
                }
              ],
              documents_relationship: [
                %{
                  type: "COURT_DECISION",
                  number: "120518"
                }
              ],
              phones: [
                %{
                  type: "MOBILE",
                  number: "+380503410870"
                }
              ]
            }
          ]
        },
        employee: %{
          id: UUID.generate(),
          position: "P6",
          party: %{
            id: UUID.generate(),
            first_name: "Петро",
            last_name: "Іванов",
            second_name: "Миколайович",
            email: "email@example.com",
            phones: [
              %{
                type: "MOBILE",
                number: "+380503410870"
              }
            ],
            tax_id: "12345678"
          }
        },
        legal_entity: %{
          id: UUID.generate(),
          name: "Клініка Борис",
          short_name: "Борис",
          legal_form: "140",
          edrpou: "5432345432"
        },
        division: %{
          id: UUID.generate(),
          name: "Бориспільське відділення Клініки Борис",
          type: "CLINIC",
          status: "NEW"
        }
      },
      status: "NEW",
      inserted_by: uuid,
      updated_by: uuid,
      authentication_method_current: %{"type" => "NA"},
      printout_content: "",
      declaration_id: UUID.generate()
    }
  end

  defp assert_count_declaration_request_list(resp, count \\ 0) do
    assert_list_response_schema(resp["data"], "declaration_request")

    assert Map.has_key?(resp, "data")
    assert Map.has_key?(resp, "paging")
    assert is_list(resp["data"])
    assert count == length(resp["data"])
  end

  defp get_person do
    %{
      tax_id: "3378115538",
      secret: "secret",
      second_name: "TestQOA",
      process_disclosure_data_consent: true,
      phones: [
        %{
          type: "MOBILE",
          number: "+380955947998"
        }
      ],
      patient_signed: true,
      last_name: "TestQOA",
      gender: "MALE",
      first_name: "TestQOA",
      emergency_contact: %{
        second_name: "Миколайович",
        phones: [
          %{
            type: "MOBILE",
            number: "+380503410870"
          }
        ],
        last_name: "Іванов",
        first_name: "Петро"
      },
      email: "qq2234562qq@gmail.com",
      documents: [
        %{
          type: "PASSPORT",
          number: "120518"
        }
      ],
      confidant_person: [
        %{
          tax_id: "3378115538",
          secret: "secret",
          second_name: "Миколайович",
          relation_type: "PRIMARY",
          phones: [
            %{
              type: "MOBILE",
              number: "+380503410870"
            }
          ],
          last_name: "Іванов",
          gender: "MALE",
          first_name: "Петро",
          documents_relationship: [
            %{
              type: "DOCUMENT",
              number: "120518"
            }
          ],
          documents_person: [
            %{
              type: "PASSPORT",
              number: "120518"
            }
          ],
          birth_settlement: "Вінниця",
          birth_date: "1991-08-19",
          birth_country: "Україна"
        },
        %{
          tax_id: "3378115538",
          secret: "secret",
          second_name: "Миколайович",
          relation_type: "SECONDARY",
          phones: [
            %{
              type: "MOBILE",
              number: "+380503410870"
            }
          ],
          last_name: "Іванов",
          gender: "MALE",
          first_name: "Петро",
          documents_relationship: [
            %{
              type: "DOCUMENT",
              number: "120518"
            }
          ],
          documents_person: [
            %{
              type: "PASSPORT",
              number: "120518"
            }
          ],
          birth_settlement: "Вінниця",
          birth_date: "1991-08-19",
          birth_country: "Україна"
        }
      ],
      birth_settlement: "Вінниця",
      birth_date: "2001-08-19",
      birth_country: "Україна",
      authentication_methods: [
        %{
          type: "OTP",
          phone_number: "+380955947998"
        }
      ],
      addresses: [
        %{
          zip: "02090",
          type: "REGISTRATION",
          street_type: "STREET",
          street: "Ніжинська",
          settlement_type: "CITY",
          settlement_id: "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
          settlement: "СОРОКИ-ЛЬВІВСЬКІ",
          region: "ПУСТОМИТІВСЬКИЙ",
          country: "UA",
          building: "15",
          area: "ЛЬВІВСЬКА",
          apartment: "23"
        },
        %{
          zip: "02090",
          type: "RESIDENCE",
          street_type: "STREET",
          street: "Ніжинська",
          settlement_type: "CITY",
          settlement_id: "707dbc55-cb6b-4aaa-97c1-2a1e03476100",
          settlement: "СОРОКИ-ЛЬВІВСЬКІ",
          region: "ПУСТОМИТІВСЬКИЙ",
          country: "UA",
          building: "15",
          area: "ЛЬВІВСЬКА",
          apartment: "23"
        }
      ]
    }
  end
end
