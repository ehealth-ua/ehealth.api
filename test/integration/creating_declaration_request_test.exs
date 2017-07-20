defmodule EHealth.Integration.DeclarationRequestCreateTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  describe "Happy paths" do
    defmodule TwoHappyPaths do
      use MicroservicesHelper

      # PRM API
      Plug.Router.get "/employees/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        employee = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "position" => "some_position",
          "party" => %{
            "id" => "some_id",
            "second_name" => "some_second_name",
            "first_name" => "some_first_name",
            "last_name" => "some_last_name",
            "email" => "some_email",
            "phones" => [],
          },
          "legal_entity_id" => "8799e3b6-34e7-4798-ba70-d897235d2b6d",
          "doctor" => %{
            "specialities" => [
              %{
                "speciality" => "PEDIATRICIAN"
              }
            ]
          }
        }

        send_resp(conn, 200, Poison.encode!(%{data: employee}))
      end

      Plug.Router.get "/global_parameters" do
        parameters = %{
          adult_age: "18",
          declaration_request_term: "40",
          declaration_request_term_unit: "YEARS"
        }

        send_resp(conn, 200, Poison.encode!(%{data: parameters}))
      end

      Plug.Router.get "/divisions/51f56b0e-0223-49c1-9b5f-b07e09ba40f1" do
        division = %{
          id: "51f56b0e-0223-49c1-9b5f-b07e09ba40f1",
          legal_entity_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d",
          addresses: [],
          phones: [],
          external_id: "7ae4bbd6-a9e7-4ce0-992b-6a1b18a262dc",
          type: "some",
          email: "some",
          name: "some"
        }

        send_resp(conn, 200, Poison.encode!(%{data: division}))
      end

      Plug.Router.get "/legal_entities/8799e3b6-34e7-4798-ba70-d897235d2b6d" do
        legal_entity = %{
          id: "8799e3b6-34e7-4798-ba70-d897235d2b6d",
          name: "nice",
          short_name: "some",
          medical_service_provider: %{
            accreditation: %{
              category: "some",
              order_date: "some",
              expiry_date: "some",
              issued_date: "some",
              order_no: "some"
            },
            licenses: []
          },
          phones: [],
          legal_form: "yoyo",
          edrpou: "some_edrpou",
          public_name: "some_name",
          email: "some",
          addresses: []
        }

        send_resp(conn, 200, Poison.encode!(%{data: legal_entity}))
      end

      # MPI API
      Plug.Router.get "/persons" do
        confirm_params =
          conn
          |> Plug.Conn.fetch_query_params(conn)
          |> Map.get(:params)

        search_result =
          case confirm_params["first_name"] do
            "Олена" ->
              [%{id: "b5350f79-f2ca-408f-b15d-1ae0a8cc861c"}]
            "UnknownMIS" ->
              []
          end

        send_resp(conn, 200, Poison.encode!(%{data: search_result}))
      end

      # MPI API
      Plug.Router.get "/persons/b5350f79-f2ca-408f-b15d-1ae0a8cc861c" do
        person = %{
          "authentication_methods": [
            %{"type": "OTP", "phone_number": "+380508887700"}
          ]
        }

        send_resp(conn, 200, Poison.encode!(%{data: person}))
      end

      # MAN Templates API
      Plug.Router.post "/templates/4/actions/render" do
        template = "<html><body>Printout form for declaration \
request ##{conn.body_params["declaration_request_id"]}</body></hrml>"

        Plug.Conn.send_resp(conn, 200, template)
      end

      # AEL, Media Storage API
      Plug.Router.post "/media_content_storage_secrets" do
        params = conn.body_params["secret"]

        upload = %{
          secret_url: "http://some_resource.com/#{params["resource_id"]}/#{params["resource_name"]}"
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{data: upload}))
      end

      # UAddresses API
      Plug.Router.get "/settlements/adaa4abf-f530-461c-bcbf-a0ac210d955b" do
        settlement = %{
          id: "adaa4abf-f530-461c-bcbf-a0ac210d955b",
          region_id: "555dfcd7-2be5-4417-aaaf-ca95564f7977",
          name: "Київ"
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{meta: "", data: settlement}))
      end

      # UAddresses API
      Plug.Router.get "/regions/555dfcd7-2be5-4417-aaaf-ca95564f7977" do
        region = %{
          name: "М.КИЇВ"
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{meta: "", data: region}))
      end

      # OTP Verifications
      Plug.Router.get "/verifications/+380508887700" do
        send_resp(conn, 200, Poison.encode!(%{data: ["response_we_don't_care_about"]}))
      end

      Plug.Router.post "/verifications" do
        "+380508887700" = conn.body_params["phone_number"]

        send_resp(conn, 200, Poison.encode!(%{data: ["response_we_don't_care_about"]}))
      end

      Plug.Router.post "/api/v1/tables/some_gndf_table_id/decisions" do
        decision = %{
          "final_decision": "OFFLINE"
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{data: decision}))
      end

      match _ do
        request_info = Enum.join([conn.request_path, conn.query_string], ",")
        message = "Requested #{request_info}, but there was no such route."

        require Logger
        Logger.error(message)

        send_resp(conn, 404, Poison.encode!(%{}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(TwoHappyPaths)

      System.put_env("PRM_ENDPOINT", "http://localhost:#{port}")
      System.put_env("MPI_ENDPOINT", "http://localhost:#{port}")
      System.put_env("GNDF_ENDPOINT", "http://localhost:#{port}")
      System.put_env("MAN_ENDPOINT", "http://localhost:#{port}")
      System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:#{port}")
      System.put_env("UADDRESS_ENDPOINT", "http://localhost:#{port}")
      System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("PRM_ENDPOINT", "http://localhost:4040")
        System.put_env("MPI_ENDPOINT", "http://localhost:4040")
        System.put_env("GNDF_ENDPOINT", "http://localhost:4040")
        System.put_env("MAN_ENDPOINT", "http://localhost:4040")
        System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:4040")
        System.put_env("UADDRESS_ENDPOINT", "http://localhost:4040")
        System.put_env("OTP_VERIFICATION_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, %{port: port, conn: conn}}
    end

    test "declaration request is created with 'OTP' verification", %{conn: conn} do
      declaration_request_params = File.read!("test/data/declaration_request.json")

      decoded = Poison.decode!(declaration_request_params)["declaration_request"]
      d1 = clone_declaration_request(decoded, "8799e3b6-34e7-4798-ba70-d897235d2b6d", "NEW")
      d2 = clone_declaration_request(decoded, "8799e3b6-34e7-4798-ba70-d897235d2b6d", "APPROVED")

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post("/api/declaration_requests", declaration_request_params)

      resp = json_response(conn, 200)

      id = resp["data"]["id"]

      schema =
        "test/data/declaration_request/create_api_response_schema.json"
        |> File.read!()
        |> Poison.decode!()

      :ok = NExJsonSchema.Validator.validate(schema, resp["data"])

      assert to_string(Date.utc_today) == resp["data"]["start_date"]
      assert {:ok, _} = Date.from_iso8601(resp["data"]["end_date"])

      declaration_request = EHealth.DeclarationRequest.API.get_declaration_request_by_id!(id)
      assert id == declaration_request.data["id"]
      assert declaration_request.data["legal_entity"]["id"]
      assert declaration_request.data["division"]["id"]
      assert declaration_request.data["employee"]["id"]
      # TODO: turn this into DB checks
      #
      # assert "NEW" = resp["status"]
      # assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" = resp["data"]["updated_by"]
      # assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" = resp["data"]["inserted_by"]
      # assert %{"number" => "+380508887700", "type" => "OTP"} = resp["authentication_method_current"]
      assert "<html><body>Printout form for declaration request ##{id}</body></hrml>" ==
        resp["data"]["content"]
      assert is_nil(resp["data"]["urgent"]["documents"])

      assert "CANCELLED" = EHealth.Repo.get(EHealth.DeclarationRequest, d1.id).status
      assert "CANCELLED" = EHealth.Repo.get(EHealth.DeclarationRequest, d2.id).status
    end

    test "declaration request is created with 'Offline' verification", %{conn: conn} do
      declaration_request_params =
        "test/data/declaration_request.json"
        |> File.read!
        |> Poison.decode!
        |> put_in(["declaration_request", "person", "first_name"], "UnknownMIS")

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: "8799e3b6-34e7-4798-ba70-d897235d2b6d"}))
        |> post("/api/declaration_requests", declaration_request_params)

      resp = json_response(conn, 200)

      id = resp["data"]["id"]

      schema =
        "test/data/declaration_request/create_api_response_schema.json"
        |> File.read!()
        |> Poison.decode!()

      :ok = NExJsonSchema.Validator.validate(schema, resp["data"])

      assert to_string(Date.utc_today) == resp["data"]["start_date"]
      assert {:ok, _} = Date.from_iso8601(resp["data"]["end_date"])
      # TODO: turn this into DB checks
      #
      # assert "NEW" = resp["data"]["status"]
      # assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" = resp["data"]["updated_by"]
      # assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" = resp["data"]["inserted_by"]
      # assert %{"number" => "+380508887700", "type" => "OFFLINE"} = resp["data"]["authentication_method_current"]
      assert "<html><body>Printout form for declaration request ##{id}</body></hrml>" ==
        resp["data"]["content"]
      assert [
        %{
          "type" => "person.PASSPORT",
          "url" => "http://some_resource.com/#{id}/declaration_request_person.PASSPORT.jpeg"},
        %{
          "type" => "person.SSN",
          "url" => "http://some_resource.com/#{id}/declaration_request_person.SSN.jpeg"
        },
        %{
          "type" => "confidant_person.0.PRIMARY.COURT_DECISION",
          "url" => "http://some_resource.com/#{id}/declaration_request_confidant_person.0.PRIMARY.COURT_DECISION.jpeg"
        },
        %{
          "type" => "confidant_person.0.PRIMARY.PASSPORT",
          "url" => "http://some_resource.com/#{id}/declaration_request_confidant_person.0.PRIMARY.PASSPORT.jpeg"
        },
        %{
          "type" => "confidant_person.0.PRIMARY.SSN",
          "url" => "http://some_resource.com/#{id}/declaration_request_confidant_person.0.PRIMARY.SSN.jpeg"
        }
      ] == resp["urgent"]["documents"]
    end
  end

  describe "Global parameters return 404" do
    defmodule NoParams do
      use MicroservicesHelper

      Plug.Router.get "/global_parameters" do
        response = %{
          error: %{},
          meta: %{
            url: "http://#{conn.host}:#{conn.port}/global_parameters",
            code: "404"
          }
        }

        send_resp(conn, 404, Poison.encode!(response))
      end

      Plug.Router.get "/settlements/adaa4abf-f530-461c-bcbf-a0ac210d955b" do
        settlement = %{
          id: "adaa4abf-f530-461c-bcbf-a0ac210d955b",
          region_id: "555dfcd7-2be5-4417-aaaf-ca95564f7977",
          name: "Київ"
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{meta: "", data: settlement}))
      end

      Plug.Router.get "/regions/555dfcd7-2be5-4417-aaaf-ca95564f7977" do
        region = %{
          name: "М.КИЇВ"
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{meta: "", data: region}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(NoParams)

      System.put_env("PRM_ENDPOINT", "http://localhost:#{port}")
      System.put_env("UADDRESS_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("PRM_ENDPOINT", "http://localhost:4040")
        System.put_env("UADDRESS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, %{port: port, conn: conn}}
    end

    test "returns error if global parameters do not exist", %{port: port, conn: conn} do
      declaration_request_params = File.read!("test/data/declaration_request.json")

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: ""}))
        |> post("/api/declaration_requests", declaration_request_params)

      resp = json_response(conn, 404)

      assert resp["error"] == %{
        "error" => %{},
        "meta" => %{
          "code" => "404",
          "url" => "http://localhost:#{port}/global_parameters"
        }
      }
    end
  end

  describe "Employee does not exist" do
    defmodule InvalidEmployeeID do
      use MicroservicesHelper

      Plug.Router.get "/settlements/adaa4abf-f530-461c-bcbf-a0ac210d955b" do
        settlement = %{
          id: "adaa4abf-f530-461c-bcbf-a0ac210d955b",
          region_id: "555dfcd7-2be5-4417-aaaf-ca95564f7977",
          name: "Київ"
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{meta: "", data: settlement}))
      end

      Plug.Router.get "/regions/555dfcd7-2be5-4417-aaaf-ca95564f7977" do
        region = %{
          name: "М.КИЇВ"
        }

        Plug.Conn.send_resp(conn, 200, Poison.encode!(%{meta: "", data: region}))
      end

      Plug.Router.get "/employees/2f650a5c-7a04-4615-a1e7-00fa41bf160d" do
        response = %{
          error: %{},
          meta: %{
            url: "http://#{conn.host}:#{conn.port}/employees/2f650a5c-7a04-4615-a1e7-00fa41bf160d",
            code: "404"
          }
        }

        send_resp(conn, 404, Poison.encode!(response))
      end

      Plug.Router.get "/global_parameters" do
        send_resp(conn, 200, Poison.encode!(%{data: %{}}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(InvalidEmployeeID)

      System.put_env("UADDRESS_ENDPOINT", "http://localhost:#{port}")
      System.put_env("PRM_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        # TODO: This and other instances:
        # thisi is needed while mock_services.ex still exists. Remove after mock_services.ex is gone
        System.put_env("UADDRESS_ENDPOINT", "http://localhost:4040")
        System.put_env("PRM_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, %{port: port, conn: conn}}
    end

    test "returns error if employee doesn't exist", %{port: port, conn: conn} do
      wrong_id = "2f650a5c-7a04-4615-a1e7-00fa41bf160d"

      declaration_request_params =
        "test/data/declaration_request.json"
        |> File.read!()
        |> Poison.decode!
        |> put_in(["declaration_request", "employee_id"], wrong_id)

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: ""}))
        |> post("/api/declaration_requests", declaration_request_params)

      resp = json_response(conn, 404)

      assert resp["error"] == %{
        "error" => %{},
        "meta" => %{
          "code" => "404",
          "url" => "http://localhost:#{port}/employees/2f650a5c-7a04-4615-a1e7-00fa41bf160d"
        }
      }
    end
  end

  describe "Settlement does not exist" do
    defmodule NoSettlement do
      use MicroservicesHelper

      Plug.Router.get "/settlements/adaa4abf-f530-461c-bcbf-a0ac210d955b" do
        Plug.Conn.send_resp(conn, 404, Poison.encode!(%{meta: "", data: %{}}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(NoSettlement)

      System.put_env("UADDRESS_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("UADDRESS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, %{conn: conn}}
    end

    test "validation error is returned", %{conn: conn} do
      declaration_request_params = File.read!("test/data/declaration_request.json")

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: ""}))
        |> post("/api/declaration_requests", declaration_request_params)

      assert %{
        "invalid" => [
          %{
            "entry" => "$.addresses.settlement_id",
            "entry_type" => "json_data_property",
            "rules" => [
              %{
                "description" => "settlement with id = adaa4abf-f530-461c-bcbf-a0ac210d955b does not exist",
                "params" => [],
                "rule" => "not_found"
              }
            ]
          },
          %{
            "entry" => "$.addresses.settlement_id",
            "entry_type" => "json_data_property",
            "rules" => [
              %{
                "description" => "settlement with id = adaa4abf-f530-461c-bcbf-a0ac210d955b does not exist",
                "params" => [],
                "rule" => "not_found"
              }
            ]
          }
        ],
        "message" => _,
        "type" => "validation_failed"
      } = json_response(conn, 422)["error"]
    end
  end

  def clone_declaration_request(params, legal_entity_id, status) do
    declaration_request_params = %{
      data: %{
        person: %{
          tax_id: get_in(params, ["person", "tax_id"])
        },
        employee: %{
          id: params["employee_id"]
        },
        legal_entity: %{
          id: legal_entity_id
        }
      },
      status: status,
      authentication_method_current: %{},
      documents: [],
      printout_content: "something",
      inserted_by: "f47f94fd-2d77-4b7e-b444-4955812c2a77",
      updated_by: "f47f94fd-2d77-4b7e-b444-4955812c2a77"
    }

    %EHealth.DeclarationRequest{}
    |> Ecto.Changeset.change(declaration_request_params)
    |> EHealth.Repo.insert!
  end
end
