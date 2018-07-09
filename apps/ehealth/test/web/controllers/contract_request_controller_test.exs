defmodule EHealth.Web.ContractRequestControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import Mox
  import EHealth.Expectations.Signature
  alias EHealth.ContractRequests.ContractRequest
  alias EHealth.Contracts.Contract
  alias EHealth.Employees.Employee
  alias EHealth.LegalEntities.LegalEntity
  alias EHealth.Utils.NumberGenerator
  alias Ecto.UUID
  alias EHealth.EventManagerRepo
  alias EHealth.EventManager.Event

  @contract_request_status_new ContractRequest.status(:new)
  @contract_request_status_declined ContractRequest.status(:declined)

  @forbidden_statuses_for_termination [
    ContractRequest.status(:declined),
    ContractRequest.status(:signed),
    ContractRequest.status(:terminated)
  ]

  @allowed_statuses_for_termination [
    ContractRequest.status(:new),
    ContractRequest.status(:approved),
    ContractRequest.status(:pending_nhs_sign),
    ContractRequest.status(:nhs_signed)
  ]

  describe "contract request draft" do
    test "success create draft", %{conn: conn} do
      msp()

      expect(MediaStorageMock, :create_signed_url, 2, fn _, _, resource, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://some_url/#{resource}"}}}
      end)

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> post(contract_request_path(conn, :draft))

      assert resp = json_response(conn, 200)
      assert Enum.all?(~w(id statute_url additional_document_url), &Map.has_key?(resp["data"], &1))
    end
  end

  describe "create contract request" do
    test "employee division is not active", %{conn: conn} do
      msp()
      %{legal_entity: legal_entity, employee: employee, party_user: party_user} = prepare_data()
      division = insert(:prm, :division)

      expect(MediaStorageMock, :create_signed_url, 2, fn "HEAD", _, resource, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://some_url/#{resource}"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn _, resource ->
        {:ok, %HTTPoison.Response{status_code: 200, headers: [{"etag", resource}]}}
      end)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      params = prepare_params(division, employee) |> Map.put("contractor_divisions", [division.id, UUID.generate()])
      drfo_signed_content(params, party_user.party.tax_id)

      conn =
        post(conn, contract_request_path(conn, :create, UUID.generate()), %{
          "signed_content" => params |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.contractor_divisions[0]",
                   "rules" => [
                     %{
                       "description" => "Division must be active and within current legal_entity",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 },
                 %{
                   "entry" => "$.contractor_divisions[1]",
                   "rules" => [
                     %{
                       "description" => "Division not found",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "external contractor division is not present in contract divisions", %{conn: conn} do
      msp()
      %{legal_entity: legal_entity, division: division, employee: employee, party_user: party_user} = prepare_data()

      expect(MediaStorageMock, :create_signed_url, 2, fn "HEAD", _, resource, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://some_url/#{resource}"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn _, resource ->
        {:ok, %HTTPoison.Response{status_code: 200, headers: [{"etag", resource}]}}
      end)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      %{id: external_legal_entity_id} = insert(:prm, :legal_entity)

      params =
        division
        |> prepare_params(employee)
        |> Map.delete("external_contractor_flag")
        |> Map.put("external_contractors", [
          %{
            "divisions" => [%{"id" => UUID.generate(), "medical_service" => "Послуга ПМД"}],
            "legal_entity_id" => external_legal_entity_id,
            "contract" => %{
              "number" => "1234567",
              "issued_at" => Date.to_iso8601(Date.utc_today()),
              "expires_at" => Date.to_iso8601(Date.utc_today())
            }
          }
        ])

      drfo_signed_content(params, party_user.party.tax_id)

      conn =
        post(conn, contract_request_path(conn, :create, UUID.generate()), %{
          "signed_content" => params |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)

      assert_error(
        resp,
        "$.external_contractors[0].divisions[0].id",
        "The division is not belong to contractor_divisions"
      )
    end

    test "external contractors invalid legal entity", %{conn: conn} do
      msp()

      %{
        legal_entity: legal_entity,
        division: division,
        employee: employee,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      expect(MediaStorageMock, :create_signed_url, 2, fn "HEAD", _, resource, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://some_url/#{resource}"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn _, resource ->
        {:ok, %HTTPoison.Response{status_code: 200, headers: [{"ETag", Jason.encode!(resource)}]}}
      end)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      now = Date.utc_today()
      start_date = Date.add(now, 10)
      expires_at = Date.to_iso8601(Date.add(start_date, 1))

      %{id: valid_id} = insert(:prm, :legal_entity)

      contractor =
        division
        |> prepare_params(employee, expires_at)
        |> Map.get("external_contractors")
        |> Enum.at(0)

      external_contractors = [
        %{contractor | "legal_entity_id" => UUID.generate()},
        %{contractor | "legal_entity_id" => valid_id},
        %{contractor | "legal_entity_id" => UUID.generate()}
      ]

      params =
        division
        |> prepare_params(employee, expires_at)
        |> Map.put("contractor_owner_id", owner.id)
        |> Map.put("start_date", Date.to_iso8601(start_date))
        |> Map.put("end_date", Date.to_iso8601(Date.add(now, 30)))
        |> Map.put("external_contractors", external_contractors)

      drfo_signed_content(params, party_user.party.tax_id)

      conn =
        post(conn, contract_request_path(conn, :create, UUID.generate()), %{
          "signed_content" => params |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.contractor_employee_divisions[0].division_id",
                   "rules" => [
                     %{
                       "description" => "Active $external_contractors[0].legal_entity_id does not exist",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 },
                 %{
                   "entry" => "$.contractor_employee_divisions[2].division_id",
                   "rules" => [
                     %{
                       "description" => "Active $external_contractors[2].legal_entity_id does not exist",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ],
               "type" => "validation_failed"
             } = resp["error"]
    end

    test "invalid expires_at date", %{conn: conn} do
      msp()
      %{legal_entity: legal_entity, division: division, employee: employee, party_user: party_user} = prepare_data()

      expect(MediaStorageMock, :create_signed_url, 2, fn "HEAD", _, resource, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://some_url/#{resource}"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn _, resource ->
        {:ok, %HTTPoison.Response{status_code: 200, headers: [{"etag", resource}]}}
      end)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      params =
        division
        |> prepare_params(employee, "2018-01-01")
        |> Map.put("start_date", "2018-02-01")
        |> Map.delete("external_contractor_flag")

      drfo_signed_content(params, party_user.party.tax_id)

      conn =
        post(conn, contract_request_path(conn, :create, UUID.generate()), %{
          "signed_content" => params |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)

      assert_error(
        resp,
        "$.external_contractors[0].contract.expires_at",
        "Expires date must be greater than contract start_date"
      )
    end

    test "invalid external_contractor_flag", %{conn: conn} do
      msp()
      %{legal_entity: legal_entity, division: division, employee: employee, party_user: party_user} = prepare_data()

      expect(MediaStorageMock, :create_signed_url, 2, fn "HEAD", _, resource, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://some_url/#{resource}"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn _, resource ->
        {:ok, %HTTPoison.Response{status_code: 200, headers: [{"etag", resource}]}}
      end)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      params =
        division
        |> prepare_params(employee, "2018-03-01")
        |> Map.put("start_date", "2018-02-01")
        |> Map.delete("external_contractor_flag")

      drfo_signed_content(params, party_user.party.tax_id)

      conn =
        post(conn, contract_request_path(conn, :create, UUID.generate()), %{
          "signed_content" => params |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)
      assert_error(resp, "$.external_contractor_flag", "Invalid external_contractor_flag")
    end

    test "start_date is in the past", %{conn: conn} do
      msp()
      %{legal_entity: legal_entity, division: division, employee: employee, party_user: party_user} = prepare_data()

      expect(MediaStorageMock, :create_signed_url, 2, fn "HEAD", _, resource, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://some_url/#{resource}"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn _, resource ->
        {:ok, %HTTPoison.Response{status_code: 200, headers: [{"etag", resource}]}}
      end)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      params =
        division
        |> prepare_params(employee, "2018-03-01")
        |> Map.put("start_date", "2018-02-01")

      drfo_signed_content(params, party_user.party.tax_id)

      conn =
        post(conn, contract_request_path(conn, :create, UUID.generate()), %{
          "signed_content" => params |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)
      assert_error(resp, "$.start_date", "Start date must be greater than current date")
    end

    test "start_date is too far in the future", %{conn: conn} do
      msp()
      %{legal_entity: legal_entity, division: division, employee: employee, party_user: party_user} = prepare_data()

      expect(MediaStorageMock, :create_signed_url, 2, fn "HEAD", _, resource, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://some_url/#{resource}"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn _, resource ->
        {:ok, %HTTPoison.Response{status_code: 200, headers: [{"etag", resource}]}}
      end)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      now = Date.utc_today()
      start_date = Date.add(now, 3650)

      params =
        division
        |> prepare_params(employee, Date.to_iso8601(Date.add(start_date, 1)))
        |> Map.put("start_date", Date.to_iso8601(start_date))

      drfo_signed_content(params, party_user.party.tax_id)

      conn =
        post(conn, contract_request_path(conn, :create, UUID.generate()), %{
          "signed_content" => params |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)
      assert_error(resp, "$.start_date", "Start date must be within this or next year")
    end

    test "invalid end_date", %{conn: conn} do
      msp()
      %{legal_entity: legal_entity, division: division, employee: employee, party_user: party_user} = prepare_data()

      expect(MediaStorageMock, :create_signed_url, 2, fn "HEAD", _, resource, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://some_url/#{resource}"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn _, resource ->
        {:ok, %HTTPoison.Response{status_code: 200, headers: [{"etag", resource}]}}
      end)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      now = Date.utc_today()
      start_date = Date.add(now, 10)

      params =
        division
        |> prepare_params(employee, Date.to_iso8601(Date.add(start_date, 1)))
        |> Map.put("start_date", Date.to_iso8601(start_date))
        |> Map.put("end_date", Date.to_iso8601(Date.add(now, 365 * 3)))

      drfo_signed_content(params, party_user.party.tax_id)

      conn =
        post(conn, contract_request_path(conn, :create, UUID.generate()), %{
          "signed_content" => params |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)
      assert_error(resp, "$.end_date", "The year of start_date and and date must be equal")
    end

    test "invalid contractor_owner_id", %{conn: conn} do
      msp()
      %{legal_entity: legal_entity, division: division, employee: employee, party_user: party_user} = prepare_data()

      expect(MediaStorageMock, :create_signed_url, 2, fn "HEAD", _, resource, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://some_url/#{resource}"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn _, resource ->
        {:ok, %HTTPoison.Response{status_code: 200, headers: [{"etag", resource}]}}
      end)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(party_user.user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      now = Date.utc_today()
      start_date = Date.add(now, 10)

      params =
        division
        |> prepare_params(employee, Date.to_iso8601(Date.add(start_date, 1)))
        |> Map.put("start_date", Date.to_iso8601(start_date))
        |> Map.put("end_date", Date.to_iso8601(Date.add(now, 30)))

      drfo_signed_content(params, party_user.party.tax_id)

      conn =
        post(conn, contract_request_path(conn, :create, UUID.generate()), %{
          "signed_content" => params |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)

      assert_error(
        resp,
        "$.contractor_owner_id",
        "Contractor owner must be active within current legal entity in contract request"
      )
    end

    test "invalid contract number", %{conn: conn} do
      msp()

      %{
        legal_entity: legal_entity,
        division: division,
        employee: employee,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      expect(MediaStorageMock, :create_signed_url, 2, fn "HEAD", _, resource, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://some_url/#{resource}"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn _, resource ->
        {:ok, %HTTPoison.Response{status_code: 200, headers: [{"etag", resource}]}}
      end)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      now = Date.utc_today()
      start_date = Date.add(now, 10)

      params =
        division
        |> prepare_params(employee, Date.to_iso8601(Date.add(start_date, 1)))
        |> Map.put("contractor_owner_id", owner.id)
        |> Map.put("contract_number", "invalid")
        |> Map.put("start_date", Date.to_iso8601(start_date))
        |> Map.put("end_date", Date.to_iso8601(Date.add(now, 30)))

      drfo_signed_content(params, party_user.party.tax_id)

      conn =
        post(conn, contract_request_path(conn, :create, UUID.generate()), %{
          "signed_content" => params |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)

      assert_error(
        resp,
        "$.contract_number",
        "string does not match pattern \"^\\\\d{4}-[\\\\dAEHKMPTX]{4}-[\\\\dAEHKMPTX]{4}$\"",
        "format"
      )
    end

    test "success create contract request with contract_number", %{conn: conn} do
      msp()

      %{
        legal_entity: legal_entity,
        division: division,
        employee: employee,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      expect(MediaStorageMock, :create_signed_url, 6, fn _, _, resource, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://some_url/#{resource}"}}}
      end)

      expect(MediaStorageMock, :get_signed_content, 2, fn _ -> {:ok, %{body: ""}} end)
      expect(MediaStorageMock, :delete_file, 2, fn _ -> {:ok, nil} end)
      expect(MediaStorageMock, :save_file, 2, fn _, _, _, _, _ -> {:ok, nil} end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn _, resource ->
        {:ok, %HTTPoison.Response{status_code: 200, headers: [{"ETag", Jason.encode!(resource)}]}}
      end)

      now = Date.utc_today()
      start_date = Date.add(now, 10)
      contract_number = NumberGenerator.generate_from_sequence(1, 1)

      insert(
        :prm,
        :contract,
        contract_number: contract_number,
        status: Contract.status(:verified),
        contractor_legal_entity_id: legal_entity.id
      )

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      params =
        division
        |> prepare_params(employee, Date.to_iso8601(Date.add(start_date, 1)))
        |> Map.put("contractor_owner_id", owner.id)
        |> Map.put("contract_number", contract_number)
        |> Map.drop(~w(start_date end_date))

      drfo_signed_content(params, party_user.party.tax_id)

      conn =
        post(conn, contract_request_path(conn, :create, UUID.generate()), %{
          "signed_content" => params |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 201)

      schema =
        "specs/json_schemas/contract_request/contract_request_show_response.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end

    test "success create contract request without contract_number", %{conn: conn} do
      msp()

      %{
        legal_entity: legal_entity,
        division: division,
        employee: employee,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      expect(MediaStorageMock, :create_signed_url, 6, fn _, _, resource, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://some_url/#{resource}"}}}
      end)

      expect(MediaStorageMock, :get_signed_content, 2, fn _ -> {:ok, %{body: ""}} end)
      expect(MediaStorageMock, :save_file, 2, fn _, _, _, _, _ -> {:ok, nil} end)
      expect(MediaStorageMock, :delete_file, 2, fn _ -> {:ok, nil} end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn _, resource ->
        {:ok, %HTTPoison.Response{status_code: 200, headers: [{"ETag", Jason.encode!(resource)}]}}
      end)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      now = Date.utc_today()
      start_date = Date.add(now, 10)

      params =
        division
        |> prepare_params(employee, Date.to_iso8601(Date.add(start_date, 1)))
        |> Map.put("contractor_owner_id", owner.id)
        |> Map.put("start_date", Date.to_iso8601(start_date))
        |> Map.put("end_date", Date.to_iso8601(Date.add(now, 30)))

      drfo_signed_content(params, party_user.party.tax_id)

      conn1 =
        post(conn, contract_request_path(conn, :create, UUID.generate()), %{
          "signed_content" => params |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn1, 201)

      schema =
        "specs/json_schemas/contract_request/contract_request_show_response.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end
  end

  describe "update contract_request" do
    test "user is not NHS ADMIN SIGNER", %{conn: conn} do
      msp()
      contract_request = insert(:il, :contract_request)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "OWNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)

      conn =
        patch(conn, contract_request_path(conn, :update, contract_request.id), %{
          "nhs_signer_base" => "на підставі наказу",
          "nhs_contract_price" => 50_000,
          "nhs_payment_method" => "prepayment"
        })

      assert json_response(conn, 403)
    end

    test "no contract_request found", %{conn: conn} do
      msp()

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)

      conn =
        patch(conn, contract_request_path(conn, :update, UUID.generate()), %{
          "nhs_signer_base" => "на підставі наказу",
          "nhs_contract_price" => 50_000,
          "nhs_payment_method" => "prepayment"
        })

      assert json_response(conn, 404)
    end

    test "contract_request has wrong status", %{conn: conn} do
      msp()
      contract_request = insert(:il, :contract_request, status: ContractRequest.status(:signed))

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)

      conn =
        patch(conn, contract_request_path(conn, :update, contract_request.id), %{
          "nhs_signer_base" => "на підставі наказу",
          "nhs_contract_price" => 50_000,
          "nhs_payment_method" => "prepayment"
        })

      assert resp = json_response(conn, 409)

      assert %{
               "message" => "Incorrect status of contract_request to modify it",
               "type" => "request_conflict"
             } = resp["error"]
    end

    test "success update contract_request", %{conn: conn} do
      msp()
      employee = insert(:prm, :employee)

      contract_request =
        insert(:il, :contract_request, start_date: Date.add(Date.utc_today(), 10), contractor_owner_id: employee.id)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)

      conn =
        patch(conn, contract_request_path(conn, :update, contract_request.id), %{
          "nhs_signer_base" => "на підставі наказу",
          "nhs_contract_price" => 50_000,
          "nhs_payment_method" => "prepayment"
        })

      assert resp = json_response(conn, 200)

      schema =
        "specs/json_schemas/contract_request/contract_request_show_response.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end
  end

  describe "show contract_request details" do
    setup %{conn: conn} do
      %{id: legal_entity_id_1} = insert(:prm, :legal_entity, type: "MSP")
      %{id: contract_request_id_1} = insert(:il, :contract_request, contractor_legal_entity_id: legal_entity_id_1)

      %{id: legal_entity_id_2} = insert(:prm, :legal_entity, type: "MSP")
      %{id: contract_request_id_2} = insert(:il, :contract_request, contractor_legal_entity_id: legal_entity_id_2)

      {:ok,
       %{
         conn: conn,
         legal_entity_id_1: legal_entity_id_1,
         contract_request_id_1: contract_request_id_1,
         contract_request_id_2: contract_request_id_2
       }}
    end

    test "success showing data for correct MPS client", %{conn: conn} = context do
      msp()

      expect(MediaStorageMock, :create_signed_url, 2, fn _, _, id, resource_name, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://url.com/#{id}/#{resource_name}"}}}
      end)

      resp =
        conn
        |> put_client_id_header(context.legal_entity_id_1)
        |> get(contract_request_path(conn, :show, context.contract_request_id_1))
        |> json_response(200)

      assert resp

      Enum.each(resp["urgent"]["documents"], fn urgent_data ->
        assert %{"type" => type} = urgent_data
        assert type == String.upcase(type)

        assert(Map.has_key?(urgent_data, "url"))
      end)
    end

    test "denied showing data for uncorrect MPS client", %{conn: conn} = context do
      msp()

      assert conn
             |> put_client_id_header(context.legal_entity_id_1)
             |> get(contract_request_path(conn, :show, context.contract_request_id_2))
             |> json_response(403)
    end

    test "contract_request not found", %{conn: conn} = context do
      msp()

      assert conn
             |> put_client_id_header(context.legal_entity_id_1)
             |> get(contract_request_path(conn, :show, UUID.generate()))
             |> json_response(404)
    end

    test "success showing any contract_request for NHS ADMIN client", %{conn: conn} = context do
      nhs(2)

      expect(MediaStorageMock, :create_signed_url, 4, fn _, _, id, resource_name, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://url.com/#{id}/#{resource_name}"}}}
      end)

      resp =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(contract_request_path(conn, :show, context.contract_request_id_1))
        |> json_response(200)

      assert resp

      Enum.each(resp["urgent"]["documents"], fn urgent_data ->
        assert Map.has_key?(urgent_data, "type")
        assert(Map.has_key?(urgent_data, "url"))
      end)

      resp =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(contract_request_path(conn, :show, context.contract_request_id_2))
        |> json_response(200)

      assert resp

      Enum.each(resp["urgent"]["documents"], fn urgent_data ->
        assert Map.has_key?(urgent_data, "type")
        assert(Map.has_key?(urgent_data, "url"))
      end)
    end

    test "contract_request not found for NHS ADMIN client", %{conn: conn} do
      nhs()

      assert conn
             |> put_client_id_header(UUID.generate())
             |> get(contract_request_path(conn, :show, UUID.generate()))
             |> json_response(404)
    end
  end

  describe "approve contract_request" do
    test "user is not NHS ADMIN SIGNER", %{conn: conn} do
      contract_request = insert(:il, :contract_request)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "OWNER"}]}}
      end)

      user_id = UUID.generate()
      party_user = insert(:prm, :party_user, user_id: user_id)
      legal_entity = insert(:prm, :legal_entity)

      conn =
        conn
        |> put_consumer_id_header(user_id)
        |> put_client_id_header(legal_entity.id)
        |> put_req_header("drfo", party_user.party.tax_id)

      data = %{
        "id" => contract_request.id,
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "text" => "something"
      }

      drfo_signed_content(data, party_user.party.tax_id)

      conn =
        patch(conn, contract_request_path(conn, :approve, contract_request.id), %{
          "signed_content" => data |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert json_response(conn, 403)
    end

    test "no contract_request found", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)
      conn = patch(conn, contract_request_path(conn, :approve, UUID.generate()))
      assert json_response(conn, 404)
    end

    test "contract_request has wrong status", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)

      contract_request =
        insert(
          :il,
          :contract_request,
          status: ContractRequest.status(:signed),
          contractor_legal_entity_id: legal_entity.id
        )

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      user_id = UUID.generate()
      party_user = insert(:prm, :party_user, user_id: user_id)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      data = %{
        "id" => contract_request.id,
        "contractor_legal_entity" => %{
          "id" => legal_entity.id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "text" => "something"
      }

      drfo_signed_content(data, party_user.party.tax_id)

      conn =
        patch(conn, contract_request_path(conn, :approve, contract_request.id), %{
          "signed_content" => data |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 409)

      assert %{
               "message" => "Incorrect status of contract_request to modify it",
               "type" => "request_conflict"
             } = resp["error"]
    end

    test "contractor_legal_entity not found", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      user_id = UUID.generate()
      legal_entity = insert(:prm, :legal_entity)
      party_user = insert(:prm, :party_user, user_id: user_id)
      contract_request = insert(:il, :contract_request, contractor_legal_entity_id: UUID.generate())

      data = %{
        "id" => contract_request.id,
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "text" => "something"
      }

      drfo_signed_content(data, party_user.party.tax_id)

      conn =
        conn
        |> put_consumer_id_header(user_id)
        |> put_client_id_header(legal_entity.id)
        |> put_req_header("drfo", party_user.party.tax_id)

      conn =
        patch(conn, contract_request_path(conn, :approve, contract_request.id), %{
          "signed_content" => data |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.contractor_legal_entity_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Legal entity not found",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "contractor_legal_entity is not active", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      user_id = UUID.generate()
      legal_entity = insert(:prm, :legal_entity, status: LegalEntity.status(:closed))
      contract_request = insert(:il, :contract_request, contractor_legal_entity_id: legal_entity.id)
      legal_entity = insert(:prm, :legal_entity)
      party_user = insert(:prm, :party_user, user_id: user_id)

      conn =
        conn
        |> put_consumer_id_header(user_id)
        |> put_client_id_header(legal_entity.id)
        |> put_req_header("drfo", party_user.party.tax_id)

      data = %{
        "id" => contract_request.id,
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "text" => "something"
      }

      drfo_signed_content(data, party_user.party.tax_id)

      conn =
        patch(conn, contract_request_path(conn, :approve, contract_request.id), %{
          "signed_content" => data |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.contractor_legal_entity_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Legal entity is not active",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "contractor_owner_id not found", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      user_id = UUID.generate()
      legal_entity = insert(:prm, :legal_entity)
      party_user = insert(:prm, :party_user, user_id: user_id)

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: UUID.generate()
        )

      conn =
        conn
        |> put_consumer_id_header(user_id)
        |> put_client_id_header(legal_entity.id)
        |> put_req_header("drfo", party_user.party.tax_id)

      data = %{
        "id" => contract_request.id,
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "text" => "something"
      }

      drfo_signed_content(data, party_user.party.tax_id)

      conn =
        patch(conn, contract_request_path(conn, :approve, contract_request.id), %{
          "signed_content" => data |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.contractor_owner_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" =>
                         "Contractor owner must be active within current legal entity in contract request",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "contractor_owner_id has invalid status", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      user_id = UUID.generate()
      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee, status: Employee.status(:new))
      party_user = insert(:prm, :party_user, user_id: user_id)

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee.id
        )

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      data = %{
        "id" => contract_request.id,
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "text" => "something"
      }

      drfo_signed_content(data, party_user.party.tax_id)

      conn =
        patch(conn, contract_request_path(conn, :approve, contract_request.id), %{
          "signed_content" => data |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.contractor_owner_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" =>
                         "Contractor owner must be active within current legal entity in contract request",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "employee legal_entity_id doesn't match contractor_legal_entity_id", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      user_id = UUID.generate()
      party_user = insert(:prm, :party_user, user_id: user_id)
      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee)

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee.id
        )

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      data = %{
        "id" => contract_request.id,
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "text" => "something"
      }

      drfo_signed_content(data, party_user.party.tax_id)

      conn =
        patch(conn, contract_request_path(conn, :approve, contract_request.id), %{
          "signed_content" => data |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.contractor_owner_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" =>
                         "Contractor owner must be active within current legal entity in contract request",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "employee is not owner", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee, legal_entity_id: legal_entity.id)
      user_id = UUID.generate()
      party_user = insert(:prm, :party_user, user_id: user_id)

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee.id
        )

      data = %{
        "id" => contract_request.id,
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "text" => "something"
      }

      conn =
        conn
        |> put_consumer_id_header(user_id)
        |> put_client_id_header(legal_entity.id)
        |> put_req_header("drfo", party_user.party.tax_id)

      drfo_signed_content(data, party_user.party.tax_id)

      conn =
        patch(conn, contract_request_path(conn, :approve, contract_request.id), %{
          "signed_content" => data |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.contractor_owner_id",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" =>
                         "Contractor owner must be active within current legal entity in contract request",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "contractor divisions validation errors mix", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      user_id = UUID.generate()
      legal_entity = insert(:prm, :legal_entity)
      party_user = insert(:prm, :party_user, user_id: user_id)
      contractor_division_1 = insert(:prm, :division, legal_entity: legal_entity)
      contractor_division_2 = insert(:prm, :division, legal_entity: legal_entity)

      employee =
        insert(
          :prm,
          :employee,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:owner),
          party: party_user.party
        )

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee.id,
          contractor_divisions: [contractor_division_1.id, contractor_division_2.id],
          contractor_employee_divisions: [
            %{division_id: contractor_division_1.id, employee_id: employee.id},
            %{division_id: contractor_division_2.id, employee_id: UUID.generate()},
            %{division_id: UUID.generate(), employee_id: UUID.generate()}
          ],
          nhs_signer_id: nil
        )

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      data = %{
        "id" => contract_request.id,
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "text" => "something"
      }

      drfo_signed_content(data, party_user.party.tax_id)

      conn =
        patch(conn, contract_request_path(conn, :approve, contract_request.id), %{
          "signed_content" => data |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.contractor_employee_divisions[0].employee_id",
                   "rules" => [
                     %{
                       "description" => "Employee must be active DOCTOR",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 },
                 %{
                   "entry" => "$.contractor_employee_divisions[1].employee_id",
                   "rules" => [
                     %{
                       "description" => "Employee not found",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 },
                 %{
                   "entry" => "$.contractor_employee_divisions[2].employee_id",
                   "rules" => [
                     %{
                       "description" => "Employee not found",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 },
                 %{
                   "entry" => "$.contractor_employee_divisions[2].division_id",
                   "rules" => [
                     %{
                       "description" => "Division should be among contractor_divisions",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "invalid start date", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      user_id = UUID.generate()
      legal_entity = insert(:prm, :legal_entity)
      party_user = insert(:prm, :party_user, user_id: user_id)

      employee_owner =
        insert(
          :prm,
          :employee,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:owner),
          party: party_user.party
        )

      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_doctor = insert(:prm, :employee, legal_entity_id: legal_entity.id, division: division)
      now = Date.utc_today()
      start_date = Date.add(now, 3650)

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee_owner.id,
          start_date: start_date,
          contractor_divisions: [division.id],
          contractor_employee_divisions: [
            %{
              "employee_id" => employee_doctor.id,
              "staff_units" => 0.5,
              "declaration_limit" => 2000,
              "division_id" => division.id
            }
          ],
          nhs_signer_id: nil
        )

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      data = %{
        "id" => contract_request.id,
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "text" => "something"
      }

      drfo_signed_content(data, party_user.party.tax_id)

      conn =
        patch(conn, contract_request_path(conn, :approve, contract_request.id), %{
          "signed_content" => data |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.start_date",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Start date must be within this or next year",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "success approve contract request", %{conn: conn} do
      insert(:il, :dictionary, name: "SETTLEMENT_TYPE", values: %{})
      insert(:il, :dictionary, name: "STREET_TYPE", values: %{})
      insert(:il, :dictionary, name: "SPECIALITY_TYPE", values: %{})

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      expect(ManMock, :render_template, fn _, _, _ ->
        {:ok, "<html></html>"}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      user_id = UUID.generate()
      party_user = insert(:prm, :party_user, user_id: user_id)
      legal_entity = insert(:prm, :legal_entity)

      employee_owner =
        insert(
          :prm,
          :employee,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:owner),
          party: party_user.party
        )

      division =
        insert(
          :prm,
          :division,
          legal_entity: legal_entity,
          phones: [%{"type" => "MOBILE", "number" => "+380631111111"}],
          working_hours: %{fri: [["08.00", "12.00"], ["14.00", "16.00"]]}
        )

      employee_doctor = insert(:prm, :employee, legal_entity_id: legal_entity.id, division: division)
      now = Date.utc_today()
      start_date = Date.add(now, 10)

      contract_request =
        insert(
          :il,
          :contract_request,
          nhs_signer_id: employee_owner.id,
          nhs_legal_entity_id: legal_entity.id,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee_owner.id,
          contractor_divisions: [division.id],
          contractor_employee_divisions: [
            %{
              "employee_id" => employee_doctor.id,
              "staff_units" => 0.5,
              "declaration_limit" => 2000,
              "division_id" => division.id
            }
          ],
          start_date: start_date
        )

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      data = %{
        "id" => contract_request.id,
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "text" => "something"
      }

      drfo_signed_content(data, party_user.party.tax_id)

      conn =
        patch(conn, contract_request_path(conn, :approve, contract_request.id), %{
          "signed_content" => data |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 200)

      schema =
        "specs/json_schemas/contract_request/contract_request_show_response.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end
  end

  describe "approve by msp" do
    test "success approve by msp", %{conn: conn} do
      user_id = UUID.generate()
      party_user = insert(:prm, :party_user, user_id: user_id)
      legal_entity = insert(:prm, :legal_entity)

      employee_owner =
        insert(
          :prm,
          :employee,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:owner),
          party: party_user.party
        )

      division =
        insert(
          :prm,
          :division,
          legal_entity: legal_entity,
          phones: [%{"type" => "MOBILE", "number" => "+380631111111"}],
          working_hours: %{fri: [["08.00", "12.00"], ["14.00", "16.00"]]}
        )

      employee_doctor = insert(:prm, :employee, legal_entity_id: legal_entity.id, division: division)
      now = Date.utc_today()
      start_date = Date.add(now, 10)

      contract_request =
        insert(
          :il,
          :contract_request,
          status: ContractRequest.status(:approved),
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee_owner.id,
          contractor_divisions: [division.id],
          contractor_employee_divisions: [
            %{
              "employee_id" => employee_doctor.id,
              "staff_units" => 0.5,
              "declaration_limit" => 2000,
              "division_id" => division.id
            }
          ],
          start_date: start_date
        )

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)

      conn = patch(conn, contract_request_path(conn, :approve_msp, contract_request.id))
      assert resp = json_response(conn, 200)

      schema =
        "specs/json_schemas/contract_request/contract_request_show_response.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end

    test "invalid contractor_owner_id", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)

      contract_request =
        insert(
          :il,
          :contract_request,
          status: ContractRequest.status(:approved)
        )

      conn = put_client_id_header(conn, legal_entity.id)
      conn = patch(conn, contract_request_path(conn, :approve_msp, contract_request.id))
      assert json_response(conn, 403)
    end

    test "contract_request not found", %{conn: conn} do
      conn = put_client_id_header(conn, UUID.generate())
      conn = patch(conn, contract_request_path(conn, :approve_msp, UUID.generate()))
      assert json_response(conn, 404)
    end
  end

  describe "terminate contract_request" do
    test "success contract_request terminating", %{conn: conn} do
      msp(4)
      user_id = UUID.generate()
      party_user = insert(:prm, :party_user, user_id: user_id)
      legal_entity = insert(:prm, :legal_entity)

      employee_owner =
        insert(
          :prm,
          :employee,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:owner),
          party: party_user.party
        )

      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_doctor = insert(:prm, :employee, legal_entity_id: legal_entity.id, division: division)

      for status <- @allowed_statuses_for_termination do
        contract_request =
          insert(
            :il,
            :contract_request,
            status: status,
            contractor_legal_entity_id: legal_entity.id,
            contractor_owner_id: employee_owner.id,
            contractor_employee_divisions: [
              %{
                "employee_id" => employee_doctor.id,
                "staff_units" => 0.5,
                "declaration_limit" => 2000,
                "division_id" => division.id
              }
            ]
          )

        conn_resp =
          conn
          |> put_client_id_header(legal_entity.id)
          |> put_consumer_id_header(user_id)
          |> patch(contract_request_path(conn, :terminate, contract_request.id), %{
            "status_reason" => "Неправильний період контракту"
          })

        assert resp = json_response(conn_resp, 200)

        schema =
          "specs/json_schemas/contract_request/contract_request_show_response.json"
          |> File.read!()
          |> Jason.decode!()

        assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])

        assert resp["data"]["status"] == ContractRequest.status(:terminated)
      end
    end

    test "contract_request not found", %{conn: conn} do
      msp()
      user_id = UUID.generate()
      legal_entity = insert(:prm, :legal_entity)

      assert conn
             |> put_client_id_header(legal_entity.id)
             |> put_consumer_id_header(user_id)
             |> patch(contract_request_path(conn, :terminate, UUID.generate()), %{
               "status_reason" => "Неправильний період контракту"
             })
             |> json_response(404)
    end

    test "legal_entity_id doesn't match contractor_legal_entity_id", %{conn: conn} do
      msp()
      legal_entity = insert(:prm, :legal_entity)
      contract_request = insert(:il, :contract_request, contractor_legal_entity_id: UUID.generate())

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> patch(contract_request_path(conn, :terminate, contract_request.id), %{
          "status_reason" => "Неправильний період контракту"
        })

      assert resp = json_response(conn, 403)
      assert %{"message" => "User is not allowed to perform this action"} = resp["error"]
    end

    test "employee legal_entity_id doesn't match contractor_legal_entity_id", %{conn: conn} do
      msp()
      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee)

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee.id
        )

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> patch(contract_request_path(conn, :terminate, contract_request.id), %{
          "status_reason" => "Неправильний період контракту"
        })

      assert resp = json_response(conn, 403)
      assert %{"message" => "User is not allowed to perform this action"} = resp["error"]
    end

    test "employee is not owner", %{conn: conn} do
      msp()
      legal_entity = insert(:prm, :legal_entity)
      employee = insert(:prm, :employee, legal_entity_id: legal_entity.id)

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee.id
        )

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> patch(contract_request_path(conn, :terminate, contract_request.id), %{
          "status_reason" => "Неправильний період контракту"
        })

      assert resp = json_response(conn, 403)
      assert %{"message" => "User is not allowed to perform this action"} = resp["error"]
    end

    test "contract_request has wrong status", %{conn: conn} do
      msp(3)
      user_id = UUID.generate()
      party_user = insert(:prm, :party_user, user_id: user_id)
      legal_entity = insert(:prm, :legal_entity)

      employee_owner =
        insert(
          :prm,
          :employee,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:owner),
          party: party_user.party
        )

      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_doctor = insert(:prm, :employee, legal_entity_id: legal_entity.id, division: division)

      for status <- @forbidden_statuses_for_termination do
        contract_request =
          insert(
            :il,
            :contract_request,
            status: status,
            contractor_legal_entity_id: legal_entity.id,
            contractor_owner_id: employee_owner.id,
            contractor_employee_divisions: [
              %{
                "employee_id" => employee_doctor.id,
                "staff_units" => 0.5,
                "declaration_limit" => 2000,
                "division_id" => division.id
              }
            ]
          )

        conn_resp =
          conn
          |> put_client_id_header(legal_entity.id)
          |> put_consumer_id_header(user_id)
          |> patch(contract_request_path(conn, :terminate, contract_request.id), %{
            "status_reason" => "Неправильний період контракту"
          })

        assert resp = json_response(conn_resp, 422)

        assert %{
                 "invalid" => [
                   %{"entry_type" => "request", "rules" => [%{"rule" => "json"}]}
                 ],
                 "message" => "Incorrect status of contract_request to modify it",
                 "type" => "request_malformed"
               } = resp["error"]
      end
    end

    test "event manager successful registration", %{conn: conn} do
      msp()
      user_id = UUID.generate()
      party_user = insert(:prm, :party_user, user_id: user_id)
      legal_entity = insert(:prm, :legal_entity)

      employee_owner =
        insert(
          :prm,
          :employee,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:owner),
          party: party_user.party
        )

      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_doctor = insert(:prm, :employee, legal_entity_id: legal_entity.id, division: division)

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee_owner.id,
          contractor_employee_divisions: [
            %{
              "employee_id" => employee_doctor.id,
              "staff_units" => 0.5,
              "declaration_limit" => 2000,
              "division_id" => division.id
            }
          ]
        )

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> patch(contract_request_path(conn, :terminate, contract_request.id), %{
          "status_reason" => "Неправильний період контракту"
        })

      assert json_response(conn, 200)

      contract_request_id = contract_request.id
      contract_request_status = ContractRequest.status(:terminated)

      assert event = EventManagerRepo.one(Event)

      assert %Event{
               entity_type: "ContractRequest",
               event_type: "StatusChangeEvent",
               entity_id: ^contract_request_id,
               properties: %{"status" => %{"new_value" => ^contract_request_status}}
             } = event
    end
  end

  describe "search contract request" do
    setup do
      nhs_signer_id = UUID.generate()
      contract_number = UUID.generate()
      contractor_owner_id = UUID.generate()
      legal_entity_id_1 = UUID.generate()
      legal_entity_id_2 = UUID.generate()

      insert(:prm, :legal_entity, type: "MSP", id: legal_entity_id_1)
      insert(:prm, :legal_entity, type: "NHS", id: legal_entity_id_2)
      insert(:il, :contract_request, %{issue_city: "Львів"})

      insert(:il, :contract_request, %{
        issue_city: "Київ",
        contractor_legal_entity_id: legal_entity_id_1,
        contract_number: contract_number
      })

      insert(:il, :contract_request, %{
        issue_city: "Київ",
        contractor_legal_entity_id: legal_entity_id_1,
        nhs_signer_id: nhs_signer_id
      })

      insert(:il, :contract_request, %{
        issue_city: "Львів",
        contractor_legal_entity_id: legal_entity_id_1,
        status: ContractRequest.status(:declined)
      })

      insert(:il, :contract_request, %{
        issue_city: "Київ",
        contractor_legal_entity_id: legal_entity_id_2,
        contractor_owner_id: contractor_owner_id
      })

      insert(:il, :contract_request, %{
        issue_city: "Львів",
        nhs_signer_id: nhs_signer_id,
        status: ContractRequest.status(:signed)
      })

      {:ok,
       %{
         nhs_signer_id: nhs_signer_id,
         contract_number: contract_number,
         contractor_owner_id: contractor_owner_id,
         legal_entity_id_1: legal_entity_id_1,
         legal_entity_id_2: legal_entity_id_2
       }}
    end

    test "finds by status as MSP", %{
      conn: conn,
      legal_entity_id_1: legal_entity_id
    } do
      msp(2)
      %{"data" => response_data} = do_get_contract_request(conn, legal_entity_id, %{"status" => "New"})
      assert [%{"status" => @contract_request_status_new}, _] = response_data

      %{"data" => response_data} =
        do_get_contract_request(conn, legal_entity_id, %{"issue_city" => "ЛЬВІВ", "status" => "declined"})

      assert [%{"status" => @contract_request_status_declined}] = response_data
    end

    test "find by status as NHS", %{
      conn: conn,
      legal_entity_id_2: legal_entity_id
    } do
      nhs()
      %{"data" => response_data} = do_get_contract_request(conn, legal_entity_id, %{"status" => "new"})
      assert 4 === length(response_data)
    end

    test "finds by issue city", %{conn: conn, legal_entity_id_1: legal_entity_id_1} do
      msp()
      %{"data" => response_data} = do_get_contract_request(conn, legal_entity_id_1, %{"issue_city" => "КИЇВ"})
      assert 2 === length(response_data)
    end

    test "finds by attributtes as MSP", %{
      conn: conn,
      contract_number: contract_number,
      legal_entity_id_1: legal_entity_id
    } do
      msp(2)

      %{"data" => response_data} =
        do_get_contract_request(conn, legal_entity_id, %{"contract_number" => contract_number})

      assert [%{"contract_number" => ^contract_number}] = response_data

      %{"data" => response_data} =
        do_get_contract_request(conn, legal_entity_id, %{"contractor_legal_entity_id" => legal_entity_id})

      assert [%{"contractor_legal_entity_id" => ^legal_entity_id}, _, _] = response_data
    end

    test "finds by attributtes as NHS", %{
      conn: conn,
      contractor_owner_id: contractor_owner_id,
      nhs_signer_id: nhs_signer_id,
      legal_entity_id_2: legal_entity_id
    } do
      nhs(2)

      %{"data" => response_data} =
        do_get_contract_request(conn, legal_entity_id, %{"contractor_owner_id" => contractor_owner_id})

      assert [%{"contractor_owner_id" => ^contractor_owner_id}] = response_data

      %{"data" => response_data} = do_get_contract_request(conn, legal_entity_id, %{"nhs_signer_id" => nhs_signer_id})

      assert [%{"nhs_signer_id" => ^nhs_signer_id}, _] = response_data
    end

    test "finds nothing", %{conn: conn, legal_entity_id_1: legal_entity_id_1} do
      msp()
      assert %{"data" => []} = do_get_contract_request(conn, legal_entity_id_1, %{"contract_number" => UUID.generate()})
    end
  end

  defp do_get_contract_request(conn, client_id, search_params) do
    conn =
      conn
      |> put_client_id_header(client_id)
      |> get(contract_request_path(conn, :index), search_params)

    json_response(conn, 200)
  end

  describe "sign nhs" do
    test "no contract_request found", %{conn: conn} do
      nhs()

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> patch(contract_request_path(conn, :sign_nhs, UUID.generate()))

      assert json_response(conn, 404)
    end

    test "invalid client_id", %{conn: conn} do
      contract_request = insert(:il, :contract_request)
      nhs()

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> patch(contract_request_path(conn, :sign_nhs, contract_request.id), %{
          "signed_content" => "",
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 403)
      assert %{"message" => "Invalid client_id", "type" => "forbidden"} = resp["error"]
    end

    test "contract_request already signed", %{conn: conn} do
      nhs()

      %{"client_id" => client_id, "user_id" => user_id, "contract_request" => contract_request} =
        prepare_nhs_sign_params(status: ContractRequest.status(:nhs_signed))

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)

      conn =
        patch(conn, contract_request_path(conn, :sign_nhs, contract_request.id), %{
          "signed_content" => "",
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)
      assert_error(resp, "The contract was already signed by NHS")
    end

    test "failed to decode signed content", %{conn: conn} do
      nhs()
      invalid_signed_content()

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request
      } = prepare_nhs_sign_params(status: ContractRequest.status(:pending_nhs_sign))

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)

      conn =
        patch(conn, contract_request_path(conn, :sign_nhs, contract_request.id), %{
          "signed_content" => "invalid",
          "signed_content_encoding" => "base64"
        })

      %{"error" => %{"invalid" => [%{"rules" => [%{"description" => err_descr}]}]}} = json_response(conn, 422)
      assert "Not a base64 string" == err_descr
    end

    test "content doesn't match", %{conn: conn} do
      insert(:il, :dictionary, name: "SETTLEMENT_TYPE", values: %{})
      insert(:il, :dictionary, name: "STREET_TYPE", values: %{})
      insert(:il, :dictionary, name: "SPECIALITY_TYPE", values: %{})
      insert(:il, :dictionary, name: "MEDICAL_SERVICE", values: %{})
      nhs()

      expect(ManMock, :render_template, fn _, _, _ ->
        {:ok, "<html></html>"}
      end)

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "party_user" => party_user
      } = prepare_nhs_sign_params(status: ContractRequest.status(:pending_nhs_sign))

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      data = %{"id" => contract_request.id, "printout_content" => "<html></html>"}
      drfo_signed_content(data, party_user.party.tax_id)

      conn =
        patch(conn, contract_request_path(conn, :sign_nhs, contract_request.id), %{
          "signed_content" => data |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)
      assert_error(resp, "Signed content does not match the previously created content")
    end

    test "invalid status", %{conn: conn} do
      id = UUID.generate()
      data = %{"id" => id, "printout_content" => "<html></html>", "contract_number" => "0000-9EAX-XT7X-3115"}
      nhs()

      %{
        "client_id" => client_id,
        "party_user" => party_user,
        "user_id" => user_id,
        "contract_request" => contract_request
      } = prepare_nhs_sign_params(id: id, data: data)

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      conn =
        patch(conn, contract_request_path(conn, :sign_nhs, contract_request.id), %{
          "signed_content" => data |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 409)

      assert %{
               "message" => "Incorrect status of contract_request to modify it",
               "type" => "request_conflict"
             } = resp["error"]
    end

    test "failed to save signed content", %{conn: conn} do
      insert(:il, :dictionary, name: "SETTLEMENT_TYPE", values: %{})
      insert(:il, :dictionary, name: "STREET_TYPE", values: %{})
      insert(:il, :dictionary, name: "SPECIALITY_TYPE", values: %{})
      insert(:il, :dictionary, name: "MEDICAL_SERVICE", values: %{})
      nhs()

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:error, "failed to save content"}
      end)

      expect(ManMock, :render_template, fn _, _, _ ->
        {:ok, "<html></html>"}
      end)

      id = UUID.generate()

      data = %{
        "id" => id,
        "printout_content" => "<html></html>",
        "contract_number" => "0000-9EAX-XT7X-3115",
        "status" => ContractRequest.status(:pending_nhs_sign)
      }

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "party_user" => party_user
      } =
        prepare_nhs_sign_params(
          id: id,
          data: data,
          status: ContractRequest.status(:pending_nhs_sign)
        )

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      drfo_signed_content(data, party_user.party.tax_id)

      conn =
        patch(conn, contract_request_path(conn, :sign_nhs, contract_request.id), %{
          "signed_content" => data |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 502)
      assert %{"message" => "Failed to save signed content"} = resp["error"]
    end

    test "success to sign contract_request", %{conn: conn} do
      insert(:il, :dictionary, name: "SETTLEMENT_TYPE", values: %{})
      insert(:il, :dictionary, name: "STREET_TYPE", values: %{})
      insert(:il, :dictionary, name: "SPECIALITY_TYPE", values: %{})
      insert(:il, :dictionary, name: "MEDICAL_SERVICE", values: %{})
      nhs()

      expect(ManMock, :render_template, fn _, _, _ ->
        {:ok, "<html></html>"}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      id = UUID.generate()

      data = %{
        "id" => id,
        "contract_number" => "0000-9EAX-XT7X-3115",
        "status" => ContractRequest.status(:pending_nhs_sign)
      }

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "party_user" => party_user
      } =
        prepare_nhs_sign_params(
          id: id,
          data: data,
          status: ContractRequest.status(:pending_nhs_sign)
        )

      data = Map.put(data, "printout_content", "<html></html>")

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", party_user.party.tax_id)

      drfo_signed_content(data, party_user.party.tax_id)

      conn =
        patch(conn, contract_request_path(conn, :sign_nhs, contract_request.id), %{
          "signed_content" => data |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      contract_request = EHealth.Repo.get(ContractRequest, contract_request.id)
      assert contract_request.nhs_signed_date == Date.utc_today()
      assert resp = json_response(conn, 200)

      schema =
        "specs/json_schemas/contract_request/contract_request_show_response.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end
  end

  describe "decline contract_request" do
    test "success decline contract request and event manager registration", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      user_id = UUID.generate()
      party_user = insert(:prm, :party_user, user_id: user_id)
      legal_entity = insert(:prm, :legal_entity)

      employee_owner =
        insert(
          :prm,
          :employee,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:owner),
          party: party_user.party
        )

      division = insert(:prm, :division, legal_entity: legal_entity)
      employee_doctor = insert(:prm, :employee, legal_entity_id: legal_entity.id, division: division)

      contract_request =
        insert(
          :il,
          :contract_request,
          nhs_signer_id: employee_owner.id,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee_owner.id,
          contractor_employee_divisions: [
            %{
              "employee_id" => employee_doctor.id,
              "staff_units" => 0.5,
              "declaration_limit" => 2000,
              "division_id" => division.id
            }
          ]
        )

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)

      data = %{
        "id" => contract_request.id,
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "status_reason" => "Не відповідає попереднім домовленостям",
        "text" => "something"
      }

      drfo_signed_content(data, party_user.party.tax_id)

      conn =
        conn
        |> put_req_header("drfo", party_user.party.tax_id)
        |> patch(contract_request_path(conn, :decline, contract_request.id), %{
          "signed_content" => data |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 200)

      schema =
        "specs/json_schemas/contract_request/contract_request_show_response.json"
        |> File.read!()
        |> Jason.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])

      assert resp["data"]["status"] == ContractRequest.status(:declined)

      contract_request = EHealth.Repo.get(ContractRequest, contract_request.id)
      assert contract_request.status_reason == "Не відповідає попереднім домовленостям"
      assert contract_request.nhs_signer_id == user_id
      assert contract_request.nhs_legal_entity_id == legal_entity.id

      contract_request_id = contract_request.id
      contract_request_status = contract_request.status
      assert event = EventManagerRepo.one(Event)

      assert %Event{
               entity_type: "ContractRequest",
               event_type: "StatusChangeEvent",
               entity_id: ^contract_request_id,
               changed_by: ^user_id,
               properties: %{"status" => %{"new_value" => ^contract_request_status}}
             } = event
    end

    test "user is not NHS ADMIN SIGNER", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      user_id = UUID.generate()
      party_user = insert(:prm, :party_user, user_id: user_id)

      employee_owner =
        insert(
          :prm,
          :employee,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:owner),
          party: party_user.party
        )

      contract_request = insert(:il, :contract_request, nhs_signer_id: employee_owner.id)

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "OWNER"}]}}
      end)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)

      drfo_signed_content(%{}, party_user.party.tax_id)

      conn =
        conn
        |> put_req_header("drfo", party_user.party.tax_id)
        |> patch(contract_request_path(conn, :decline, contract_request.id), %{
          "signed_content" => %{} |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert json_response(conn, 403)
    end

    test "no contract_request found", %{conn: conn} do
      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)
      conn = put_client_id_header(conn, legal_entity.id)

      conn =
        patch(conn, contract_request_path(conn, :decline, UUID.generate()), %{
          "status_reason" => "Не відповідає попереднім домовленостям"
        })

      assert json_response(conn, 404)
    end

    test "contract_request has wrong status", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      user_id = UUID.generate()
      party_user = insert(:prm, :party_user, user_id: user_id)

      employee_owner =
        insert(
          :prm,
          :employee,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:owner),
          party: party_user.party
        )

      contract_request =
        insert(
          :il,
          :contract_request,
          contractor_legal_entity_id: legal_entity.id,
          status: ContractRequest.status(:signed),
          nhs_signer_id: employee_owner.id
        )

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      conn =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)

      data = %{
        "id" => contract_request.id,
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "status_reason" => "Не відповідає попереднім домовленостям",
        "text" => "something"
      }

      drfo_signed_content(data, party_user.party.tax_id)

      conn =
        conn
        |> put_req_header("drfo", party_user.party.tax_id)
        |> patch(contract_request_path(conn, :decline, contract_request.id), %{
          "signed_content" => data |> Jason.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 409)

      assert %{
               "message" => "Incorrect status of contract_request to modify it",
               "type" => "request_conflict"
             } = resp["error"]
    end
  end

  describe "get partially signed contract request url" do
    test "returns url successfully to owner", %{conn: conn} do
      msp()

      expect(MediaStorageMock, :create_signed_url, fn _, _, id, resource_name, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://url.com/#{id}/#{resource_name}"}}}
      end)

      %{user_id: user_id, owner: employee} = prepare_data()
      client_id = employee.legal_entity_id

      contract_request =
        insert(
          :il,
          :contract_request,
          status: ContractRequest.status(:nhs_signed),
          contractor_owner_id: employee.id,
          contractor_legal_entity_id: client_id
        )

      url_expected = "http://url.com/#{contract_request.id}/contract_request_content.pkcs7"

      assert %{"data" => %{"url" => ^url_expected}} =
               conn
               |> put_client_id_header(client_id)
               |> put_consumer_id_header(user_id)
               |> get(contract_request_path(conn, :get_partially_signed_content, contract_request.id))
               |> json_response(200)
    end

    test "contract request was not signed by nhs", %{conn: conn} do
      msp()
      contract_request = insert(:il, :contract_request, status: ContractRequest.status(:new))

      assert %{"error" => %{"message" => "The contract hasn't been signed yet"}} =
               conn
               |> put_client_id_header(UUID.generate())
               |> put_consumer_id_header(UUID.generate())
               |> get(contract_request_path(conn, :get_partially_signed_content, contract_request.id))
               |> json_response(422)
    end

    test "invalid client id for contractor_legal_entity_id", %{conn: conn} do
      msp()
      contract_request = insert(:il, :contract_request, status: ContractRequest.status(:nhs_signed))

      assert %{"error" => %{"type" => "forbidden", "message" => _}} =
               conn
               |> put_client_id_header(UUID.generate())
               |> put_consumer_id_header(UUID.generate())
               |> get(contract_request_path(conn, :get_partially_signed_content, contract_request.id))
               |> json_response(403)
    end

    test "media storage fail to resolve url", %{conn: conn} do
      msp()

      expect(MediaStorageMock, :create_signed_url, fn _, _, _, _, _ ->
        {:ok, %{"error" => %{}}}
      end)

      %{user_id: user_id, owner: employee} = prepare_data()
      client_id = employee.legal_entity_id

      contract_request =
        insert(
          :il,
          :contract_request,
          status: ContractRequest.status(:nhs_signed),
          contractor_owner_id: employee.id,
          contractor_legal_entity_id: client_id
        )

      assert %{"error" => _} =
               conn
               |> put_client_id_header(client_id)
               |> put_consumer_id_header(user_id)
               |> get(contract_request_path(conn, :get_partially_signed_content, contract_request.id))
               |> json_response(502)
    end
  end

  describe "sign MSP" do
    test "no contract_request found", %{conn: conn} do
      msp()
      conn = put_client_id_header(conn, UUID.generate())
      conn = patch(conn, contract_request_path(conn, :sign_msp, UUID.generate()))
      assert json_response(conn, 404)
    end

    test "invalid client_id", %{conn: conn} do
      nhs()
      contract_request = insert(:il, :contract_request, status: ContractRequest.status(:nhs_signed))
      conn = put_client_id_header(conn, UUID.generate())

      conn =
        patch(conn, contract_request_path(conn, :sign_msp, contract_request.id), %{
          "signed_content" => "",
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 403)
      assert %{"message" => "Invalid client_id", "type" => "forbidden"} = resp["error"]
    end

    test "contract_request already signed", %{conn: conn} do
      nhs()

      %{"client_id" => client_id, "user_id" => user_id, "contract_request" => contract_request} =
        prepare_nhs_sign_params(status: ContractRequest.status(:signed))

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)

      conn =
        patch(conn, contract_request_path(conn, :sign_msp, contract_request.id), %{
          "signed_content" => "",
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)
      assert_error(resp, "Incorrect status for signing")
    end

    test "failed to decode signed content", %{conn: conn} do
      nhs()

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "party_user" => party_user
      } = prepare_nhs_sign_params(status: ContractRequest.status(:nhs_signed))

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("msp_drfo", party_user.party.tax_id)

      invalid_signed_content()

      conn =
        patch(conn, contract_request_path(conn, :sign_msp, contract_request.id), %{
          "signed_content" => "invalid",
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.signed_content",
                   "entry_type" => "json_data_property",
                   "rules" => [%{"description" => "Not a base64 string", "params" => [], "rule" => "invalid"}]
                 }
               ],
               "type" => "validation_failed"
             } = resp["error"]
    end

    test "content doesn't match", %{conn: conn} do
      insert(:il, :dictionary, name: "SETTLEMENT_TYPE", values: %{})
      insert(:il, :dictionary, name: "STREET_TYPE", values: %{})
      insert(:il, :dictionary, name: "SPECIALITY_TYPE", values: %{})
      nhs()

      expect(ManMock, :render_template, fn _, _, _ ->
        {:ok, "<html></html>"}
      end)

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "party_user" => party_user
      } = prepare_nhs_sign_params(status: ContractRequest.status(:nhs_signed))

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("msp_drfo", party_user.party.tax_id)

      data = %{"id" => contract_request.id, "printout_content" => "<html></html>"}
      drfo_signed_content(data, [party_user.party.tax_id, nil])

      conn =
        patch(conn, contract_request_path(conn, :sign_msp, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 422)
      assert_error(resp, "Signed content does not match the previously created content")
    end

    test "failed to save signed content", %{conn: conn} do
      nhs()

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:error, "failed to save content"}
      end)

      id = UUID.generate()
      data = %{"id" => id, "printout_content" => nil, "status" => ContractRequest.status(:nhs_signed)}

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "party_user" => party_user
      } =
        prepare_nhs_sign_params(
          id: id,
          data: data,
          status: ContractRequest.status(:nhs_signed)
        )

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("msp_drfo", party_user.party.tax_id)

      drfo_signed_content(data, [party_user.party.tax_id, nil])

      conn =
        patch(conn, contract_request_path(conn, :sign_msp, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 502)
      assert %{"message" => "Failed to save signed content"} = resp["error"]
    end

    test "failed to create contract", %{conn: conn} do
      nhs()

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      id = UUID.generate()
      data = %{"id" => id, "printout_content" => nil, "status" => ContractRequest.status(:nhs_signed)}

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "party_user" => party_user
      } =
        prepare_nhs_sign_params(
          id: id,
          data: data,
          status: ContractRequest.status(:nhs_signed)
        )

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("msp_drfo", party_user.party.tax_id)

      drfo_signed_content(data, [party_user.party.tax_id, nil])

      conn =
        patch(conn, contract_request_path(conn, :sign_msp, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert json_response(conn, 502)
    end

    test "success to sign contract_request", %{conn: conn} do
      nhs()

      expect(ManMock, :render_template, fn _, _, _ ->
        {:ok, "<html></html>"}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      id = UUID.generate()
      data = %{"id" => id, "printout_content" => nil, "status" => ContractRequest.status(:nhs_signed)}

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "party_user" => party_user
      } =
        prepare_nhs_sign_params(
          id: id,
          data: data,
          status: ContractRequest.status(:nhs_signed),
          contract_number: "1345"
        )

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("msp_drfo", party_user.party.tax_id)

      drfo_signed_content(data, [party_user.party.tax_id, nil])

      conn =
        patch(conn, contract_request_path(conn, :sign_msp, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 200)

      schema =
        "specs/json_schemas/contract/contract_show_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end

    test "success to sign contract_request with existing parent_contract_id", %{conn: conn} do
      nhs()

      expect(ManMock, :render_template, fn _, _, _ ->
        {:ok, "<html></html>"}
      end)

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      id = UUID.generate()
      data = %{"id" => id, "printout_content" => nil, "status" => ContractRequest.status(:nhs_signed)}
      contract = insert(:prm, :contract, contract_number: "1345")
      employee = insert(:prm, :employee)
      insert(:prm, :contract_employee, contract_id: contract.id, employee_id: employee.id)
      insert(:prm, :contract_division, contract_id: contract.id)

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "party_user" => party_user
      } =
        prepare_nhs_sign_params(
          id: id,
          data: data,
          status: ContractRequest.status(:nhs_signed),
          contract_number: "1345",
          parent_contract_id: contract.id
        )

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("msp_drfo", party_user.party.tax_id)

      drfo_signed_content(data, [party_user.party.tax_id, nil])

      conn =
        patch(conn, contract_request_path(conn, :sign_msp, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })

      assert resp = json_response(conn, 200)

      schema =
        "specs/json_schemas/contract/contract_show_response.json"
        |> File.read!()
        |> Poison.decode!()

      assert :ok = NExJsonSchema.Validator.validate(schema, resp["data"])
    end
  end

  describe "get printout_form" do
    test "success get printout_form", %{conn: conn} do
      insert(:il, :dictionary, name: "SETTLEMENT_TYPE", values: %{})
      insert(:il, :dictionary, name: "STREET_TYPE", values: %{})
      insert(:il, :dictionary, name: "SPECIALITY_TYPE", values: %{})
      insert(:il, :dictionary, name: "MEDICAL_SERVICE", values: %{})
      nhs()

      printout_content = "<html></html>"

      expect(ManMock, :render_template, fn _, _, _ ->
        {:ok, printout_content}
      end)

      contract_request = insert(:il, :contract_request, status: ContractRequest.status(:pending_nhs_sign))
      id = contract_request.id

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(contract_request_path(conn, :printout_content, id))

      assert resp = json_response(conn, 200)
      assert %{"id" => id, "printout_content" => printout_content} == resp["data"]
    end

    test "invalid status", %{conn: conn} do
      contract_request = insert(:il, :contract_request)
      nhs()

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(contract_request_path(conn, :printout_content, contract_request.id))

      assert json_response(conn, 409)
    end
  end

  defp prepare_data(role_name \\ "OWNER") do
    expect(MithrilMock, :get_user_roles, fn _, _, _ ->
      {:ok, %{"data" => [%{"role_name" => role_name}]}}
    end)

    user_id = UUID.generate()
    party_user = insert(:prm, :party_user, user_id: user_id)
    legal_entity = insert(:prm, :legal_entity)

    division =
      insert(:prm, :division, legal_entity: legal_entity, phones: [%{"type" => "MOBILE", "number" => "+380631111111"}])

    employee =
      insert(
        :prm,
        :employee,
        division: division,
        legal_entity_id: legal_entity.id
      )

    owner =
      insert(
        :prm,
        :employee,
        employee_type: Employee.type(:owner),
        party: party_user.party,
        legal_entity_id: legal_entity.id
      )

    %{
      legal_entity: legal_entity,
      employee: employee,
      division: division,
      user_id: user_id,
      owner: owner,
      party_user: party_user
    }
  end

  defp prepare_params(division, employee, expires_at \\ nil) do
    %{id: external_legal_entity_id} = insert(:prm, :legal_entity)

    %{
      "contractor_owner_id" => UUID.generate(),
      "contractor_base" => "на підставі закону про Медичне обслуговування населення",
      "contractor_payment_details" => %{
        "bank_name" => "Банк номер 1",
        "MFO" => "351005",
        "payer_account" => "32009102701026"
      },
      "contractor_rmsp_amount" => 10,
      "id_form" => "5",
      "contractor_employee_divisions" => [
        %{
          "employee_id" => employee.id,
          "staff_units" => 0.5,
          "declaration_limit" => 2000,
          "division_id" => division.id
        }
      ],
      "contractor_divisions" => [division.id],
      "external_contractors" => [
        %{
          "legal_entity_id" => external_legal_entity_id,
          "contract" => %{
            "number" => "1234567",
            "issued_at" => expires_at,
            "expires_at" => expires_at
          },
          "divisions" => [
            %{
              "id" => division.id,
              "medical_service" => "Послуга ПМД"
            }
          ]
        }
      ],
      "external_contractor_flag" => true,
      "start_date" => "2018-01-01",
      "end_date" => "2018-01-01",
      "statute_md5" => "media/upload_contract_request_statute.pdf",
      "additional_document_md5" => "media/upload_contract_request_additional_document.pdf"
    }
  end

  defp prepare_nhs_sign_params(contract_request_params, legal_entity_params \\ []) do
    client_id = UUID.generate()
    params = Keyword.merge([id: client_id], legal_entity_params)
    legal_entity = insert(:prm, :legal_entity, params)
    user_id = UUID.generate()
    nhs_signer_id = Keyword.get(contract_request_params, :nhs_signer_id) || UUID.generate()
    party_user = insert(:prm, :party_user, user_id: user_id)
    insert(:prm, :employee, party: party_user.party, legal_entity_id: client_id, id: nhs_signer_id)

    division =
      insert(:prm, :division, legal_entity: legal_entity, phones: [%{"type" => "MOBILE", "number" => "+380631111111"}])

    employee_doctor = insert(:prm, :employee, legal_entity_id: legal_entity.id, division: division)

    employee_owner =
      insert(
        :prm,
        :employee,
        id: user_id,
        legal_entity_id: legal_entity.id,
        employee_type: Employee.type(:owner),
        party: party_user.party
      )

    now = Date.utc_today()
    start_date = Date.add(now, 10)

    params =
      Keyword.merge(
        [
          nhs_legal_entity_id: client_id,
          nhs_signer_id: user_id,
          contractor_legal_entity_id: client_id,
          contractor_owner_id: employee_owner.id,
          contractor_divisions: [division.id],
          contractor_employee_divisions: [
            %{
              "employee_id" => employee_doctor.id,
              "staff_units" => 0.5,
              "declaration_limit" => 2000,
              "division_id" => division.id
            }
          ],
          start_date: start_date
        ],
        contract_request_params
      )

    contract_request = insert(:il, :contract_request, params)

    %{
      "client_id" => client_id,
      "user_id" => user_id,
      "legal_entity" => legal_entity,
      "party_user" => party_user,
      "contract_request" => contract_request
    }
  end

  defp assert_error(resp, message) do
    assert %{
             "invalid" => [
               %{"entry_type" => "request", "rules" => [%{"rule" => "json"}]}
             ],
             "message" => ^message,
             "type" => "request_malformed"
           } = resp["error"]
  end

  defp assert_error(resp, entry, description, rule \\ "invalid") do
    assert %{
             "type" => "validation_failed",
             "invalid" => [
               %{
                 "rules" => [
                   %{
                     "rule" => ^rule,
                     "description" => ^description
                   }
                 ],
                 "entry_type" => "json_data_property",
                 "entry" => ^entry
               }
             ]
           } = resp["error"]
  end
end
