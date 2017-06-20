defmodule EHealth.Integraiton.DeclarationRequestCreateTest do
  @moduledoc false

  use EHealth.Web.ConnCase, async: false

  describe "Happy path" do
    defmodule HappyPath do
      use MicroservicesHelper

      Plug.Router.get "/employees/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        employee = %{
          "specialities" => [
            %{
              "speciality" => "PEDIATRICIAN"
            }
          ]
        }

        send_resp(conn, 200, Poison.encode!(%{data: employee}))
      end

      Plug.Router.get "/global_parameters" do
        parameters = %{
          adult_age: 18,
          declaration_request_term: 40,
          declaration_request_term_unit: "YEARS"
        }

        send_resp(conn, 200, Poison.encode!(%{data: parameters}))
      end

      Plug.Router.get "/persons" do
        confirm_params =
          conn
          |> Plug.Conn.fetch_query_params(conn)
          |> Map.get(:params)

        %{
          "first_name" => "Олена",
          "last_name" => "Пчілка",
          "phone_number" => "+380508887700",
          "birth_date" => "2010-08-19 00:00:00",
          "tax_id" => "3126509816"
        } = confirm_params

        search_result = [
          %{id: "b5350f79-f2ca-408f-b15d-1ae0a8cc861c"}
        ]

        send_resp(conn, 200, Poison.encode!(%{data: search_result}))
      end

      Plug.Router.get "/persons/b5350f79-f2ca-408f-b15d-1ae0a8cc861c" do
        person = %{
          "authentication_methods": [
            %{"type": "OTP", "number": "+380508887700"}
          ]
        }

        send_resp(conn, 200, Poison.encode!(%{data: person}))
      end

      match _ do
        send_resp(conn, 404, Poison.encode!(%{}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(HappyPath)

      System.put_env("PRM_ENDPOINT", "http://localhost:#{port}")
      System.put_env("MPI_ENDPOINT", "http://localhost:#{port}")
      System.put_env("GNDF_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("PRM_ENDPOINT", "http://localhost:4040")
        System.put_env("MPI_ENDPOINT", "http://localhost:4040")
        System.put_env("GNDF_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, %{port: port, conn: conn}}
    end

    test "declaration request is created", %{conn: conn} do
      declaration_request_params = File.read!("test/data/declaration_request.json")

      conn =
        conn
        |> put_req_header("x-consumer-id", "ce377dea-d8c4-4dd8-9328-de24b1ee3879")
        |> put_req_header("x-consumer-metadata", Poison.encode!(%{client_id: ""}))
        |> post("/api/declaration_requests", declaration_request_params)

      resp = json_response(conn, 200)

      id = resp["data"]["id"]

      assert to_string(Date.utc_today) == resp["data"]["data"]["start_date"]
      assert {:ok, _} = Date.from_iso8601(resp["data"]["data"]["end_date"])
      assert "NEW" = resp["data"]["status"]
      assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" = resp["data"]["updated_by"]
      assert "ce377dea-d8c4-4dd8-9328-de24b1ee3879" = resp["data"]["inserted_by"]
      assert %{"number" => "+380508887700", "type" => "OTP"} = resp["data"]["authentication_method_current"]
      assert "<html><body>Printout form for declaration request ##{id}</body></hrml>" ==
        resp["data"]["printout_content"]

      assert [
        %{
          "type" => "Passport",
          "url" => "http://some_resource.com/#{id}/declaration_request_Passport.jpeg"
        },
        %{
          "type" => "SSN",
          "url" => "http://some_resource.com/#{id}/declaration_request_SSN.jpeg"
        }
      ] == resp["data"]["documents"]
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
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(NoParams)

      System.put_env("PRM_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("PRM_ENDPOINT", "http://localhost:4040")
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

      resp = json_response(conn, 424)

      error_message = "Error during microservice interaction. Response from microservice: \
%{\"error\" => %{}, \"meta\" => %{\"code\" => \"404\", \"url\" => \"http://localhost:#{port}/global_parameters\"}}."
      assert error_message == resp["error"]["message"]
    end
  end

  describe "Employee does not exist" do
    defmodule InvalidEmployeeID do
      use MicroservicesHelper

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

      System.put_env("PRM_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        # TODO: This and other instances:
        # thisi is needed while mock_services.ex still exists. Remove after mock_services.ex is gone
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

      resp = json_response(conn, 424)

      error_message = "Error during microservice interaction. Response from microservice: \
%{\"error\" => %{}, \"meta\" => %{\"code\" => \"404\", \"url\" => \"http://localhost:#{port}/employees/#{wrong_id}\"}}."
      assert error_message == resp["error"]["message"]
    end
  end
end
