defmodule EHealth.Web.ContractRequest.ReimbursementControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase

  import Core.Expectations.Man
  import Core.Expectations.Signature
  import Mox

  alias Core.ContractRequests.ReimbursementContractRequest
  alias Core.Contracts.ContractDivision
  alias Core.Contracts.ReimbursementContract
  alias Core.Employees.Employee
  alias Core.EventManagerRepo
  alias Core.EventManager.Event
  alias Core.LegalEntities.LegalEntity
  alias Core.PRMRepo
  alias Core.Utils.NumberGenerator
  alias Ecto.UUID

  setup :verify_on_exit!

  @in_process ReimbursementContractRequest.status(:in_process)

  @msp LegalEntity.type(:msp)
  @nhs LegalEntity.type(:nhs)
  @pharmacy LegalEntity.type(:pharmacy)

  @reimbursement ReimbursementContractRequest.type()
  @path_type String.downcase(@reimbursement)

  @in_process ReimbursementContractRequest.status(:in_process)
  @pending_nhs_sign ReimbursementContractRequest.status(:pending_nhs_sign)

  @allowed_statuses_for_termination [
    ReimbursementContractRequest.status(:new),
    ReimbursementContractRequest.status(:approved),
    ReimbursementContractRequest.status(:pending_nhs_sign),
    ReimbursementContractRequest.status(:nhs_signed)
  ]

  describe "list reimbursement contract requests" do
    test "successfully finds only reimbursement contracts", %{conn: conn} do
      nhs()

      insert_list(2, :il, :capitation_contract_request)
      insert_list(4, :il, :reimbursement_contract_request)

      assert resp_data =
               conn
               |> put_consumer_id_header()
               |> put_client_id_header()
               |> get(contract_request_path(conn, :index, @path_type))
               |> json_response(200)
               |> Map.get("data")

      assert 4 == length(resp_data)
    end

    test "successfully finds by medical_program_id", %{conn: conn} do
      nhs()

      %{id: medical_program_id} = insert(:prm, :medical_program)
      insert_list(2, :il, :reimbursement_contract_request, medical_program_id: medical_program_id)
      insert_list(4, :il, :reimbursement_contract_request)
      insert_list(8, :il, :capitation_contract_request)

      assert resp_data =
               conn
               |> put_consumer_id_header()
               |> put_client_id_header()
               |> get(contract_request_path(conn, :index, @path_type), %{medical_program_id: medical_program_id})
               |> json_response(200)
               |> Map.get("data")

      assert 2 == length(resp_data)
    end
  end

  describe "show reimbursement contract requests" do
    test "success by PHARMACY", %{conn: conn} do
      pharmacy()

      %{id: employee_id} = insert(:prm, :employee)
      %{id: legal_entity_id} = insert(:prm, :legal_entity, type: @pharmacy)

      %{id: id} =
        insert(:il, :reimbursement_contract_request,
          contractor_legal_entity_id: legal_entity_id,
          contractor_owner_id: employee_id
        )

      expect(MediaStorageMock, :create_signed_url, 2, fn _, _, resource_name, resource_id, _ ->
        assert id == resource_id
        {:ok, %{"data" => %{"secret_url" => "http://url.com/#{id}/#{resource_name}"}}}
      end)

      expect(MediaStorageMock, :get_signed_content, 2, fn _url -> {:ok, %{status_code: 200}} end)

      conn
      |> put_consumer_id_header()
      |> put_client_id_header(legal_entity_id)
      |> get(contract_request_path(conn, :show, @path_type, id))
      |> json_response(200)
      |> Map.get("data")
      |> assert_show_response_schema("contract_request/reimbursement", "contract_request")
    end

    test "MSP not allowed see reimbursement contract", %{conn: conn} do
      msp()

      %{id: employee_id} = insert(:prm, :employee)
      %{id: legal_entity_id} = insert(:prm, :legal_entity, type: @msp)

      %{id: id} =
        insert(:il, :reimbursement_contract_request,
          contractor_legal_entity_id: legal_entity_id,
          contractor_owner_id: employee_id
        )

      err_message =
        conn
        |> put_consumer_id_header()
        |> put_client_id_header(legal_entity_id)
        |> get(contract_request_path(conn, :show, @path_type, id))
        |> json_response(403)
        |> get_in(~w(error message))

      assert "User is not allowed to perform this action" == err_message
    end

    test "success by NHS", %{conn: conn} do
      nhs()

      %{id: employee_id} = insert(:prm, :employee)
      %{id: legal_entity_id} = insert(:prm, :legal_entity, type: @nhs)

      %{id: id} =
        insert(:il, :reimbursement_contract_request,
          contractor_legal_entity_id: legal_entity_id,
          contractor_owner_id: employee_id
        )

      expect(MediaStorageMock, :create_signed_url, 2, fn _, _, resource_name, resource_id, _ ->
        assert id == resource_id
        {:ok, %{"data" => %{"secret_url" => "http://url.com/#{resource_id}/#{resource_name}"}}}
      end)

      expect(MediaStorageMock, :get_signed_content, 2, fn _url -> {:ok, %{status_code: 200}} end)

      conn
      |> put_client_id_header()
      |> get(contract_request_path(conn, :show, @path_type, id))
      |> json_response(200)
      |> Map.get("data")
      |> assert_show_response_schema("contract_request/reimbursement", "contract_request")
    end

    test "fails on not finding reimbursement contract request", %{conn: conn} do
      nhs()

      %{id: id} = insert(:il, :capitation_contract_request)

      assert conn
             |> put_client_id_header()
             |> put_consumer_id_header()
             |> get(contract_request_path(conn, :show, @path_type, id))
             |> json_response(404)
    end
  end

  describe "successful creation reimbursement contract request" do
    test "with contract_number", %{conn: conn} do
      id = UUID.generate()

      expect(MediaStorageMock, :get_signed_content, 2, fn _ -> {:ok, %{body: ""}} end)
      expect(MediaStorageMock, :delete_file, 2, fn _ -> {:ok, nil} end)
      expect(MediaStorageMock, :save_file, 2, fn _, _, _, _, _ -> {:ok, nil} end)

      expect(MediaStorageMock, :create_signed_url, 6, fn _, _, resource, resource_id, _ ->
        assert id == resource_id
        {:ok, %{"data" => %{"secret_url" => "http://some_url/#{resource}"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn _, resource ->
        {:ok, %HTTPoison.Response{status_code: 200, headers: [{"ETag", Jason.encode!(resource)}]}}
      end)

      %{
        medical_program: medical_program,
        legal_entity: legal_entity,
        division: division,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      contract_number = NumberGenerator.generate_from_sequence(1, 1)

      previous_request = insert(:il, :capitation_contract_request, contractor_legal_entity_id: legal_entity.id)

      insert(
        :prm,
        :reimbursement_contract,
        contract_number: contract_number,
        status: ReimbursementContract.status(:verified),
        contractor_legal_entity: legal_entity,
        medical_program_id: medical_program.id
      )

      params =
        division
        |> prepare_reimbursement_params(medical_program)
        |> Map.merge(%{
          "previous_request_id" => previous_request.id,
          "contractor_owner_id" => owner.id,
          "contract_number" => contract_number
        })
        |> Map.drop(~w(start_date end_date))

      expect_signed_content(params, %{
        edrpou: legal_entity.edrpou,
        drfo: party_user.party.tax_id,
        surname: party_user.party.last_name
      })

      conn
      |> put_client_id_header(legal_entity.id)
      |> put_consumer_id_header(user_id)
      |> put_req_header("drfo", legal_entity.edrpou)
      |> post(contract_request_path(conn, :create, @path_type, id), signed_content_params(params))
      |> json_response(201)
      |> Map.get("data")
      |> assert_show_response_schema("contract_request/reimbursement", "contract_request")
    end

    test "without contract_number", %{conn: conn} do
      expect(MediaStorageMock, :get_signed_content, 2, fn _ -> {:ok, %{body: ""}} end)
      expect(MediaStorageMock, :delete_file, 2, fn _ -> {:ok, nil} end)
      expect(MediaStorageMock, :save_file, 2, fn _, _, _, _, _ -> {:ok, nil} end)

      expect(MediaStorageMock, :create_signed_url, 6, fn _, _, resource, _, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://some_url/#{resource}"}}}
      end)

      expect(MediaStorageMock, :verify_uploaded_file, 2, fn _, resource ->
        {:ok, %HTTPoison.Response{status_code: 200, headers: [{"ETag", Jason.encode!(resource)}]}}
      end)

      %{
        medical_program: medical_program,
        legal_entity: legal_entity,
        division: division,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      params =
        division
        |> prepare_reimbursement_params(medical_program)
        |> Map.put("contractor_owner_id", owner.id)

      expect_signed_content(params, %{
        edrpou: legal_entity.edrpou,
        drfo: party_user.party.tax_id,
        surname: party_user.party.last_name
      })

      conn
      |> put_client_id_header(legal_entity.id)
      |> put_consumer_id_header(user_id)
      |> put_req_header("drfo", legal_entity.edrpou)
      |> post(contract_request_path(conn, :create, @path_type, UUID.generate()), signed_content_params(params))
      |> json_response(201)
      |> Map.get("data")
      |> assert_show_response_schema("contract_request/reimbursement", "contract_request")
    end

    test "without uploaded documents", %{conn: conn} do
      %{
        medical_program: medical_program,
        legal_entity: legal_entity,
        division: division,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      params =
        division
        |> prepare_reimbursement_params(medical_program)
        |> Map.put("contractor_owner_id", owner.id)
        |> Map.drop(~w(statute_md5 additional_document_md5))

      expect_signed_content(params, %{
        edrpou: legal_entity.edrpou,
        drfo: party_user.party.tax_id,
        surname: party_user.party.last_name
      })

      conn
      |> put_client_id_header(legal_entity.id)
      |> put_consumer_id_header(user_id)
      |> put_req_header("drfo", legal_entity.edrpou)
      |> post(contract_request_path(conn, :create, @path_type, UUID.generate()), signed_content_params(params))
      |> json_response(201)
      |> Map.get("data")
      |> assert_show_response_schema("contract_request/reimbursement", "contract_request")
    end
  end

  describe "failed reimbursement contract request creation" do
    test "duplicated id", %{conn: conn} do
      contract_request = insert(:il, :reimbursement_contract_request)

      %{
        medical_program: medical_program,
        legal_entity: legal_entity,
        division: division,
        user_id: user_id,
        owner: owner
      } = prepare_data()

      contract_number = NumberGenerator.generate_from_sequence(1, 1)

      insert(
        :prm,
        :reimbursement_contract,
        contract_number: contract_number,
        status: ReimbursementContract.status(:verified),
        contractor_legal_entity: legal_entity,
        medical_program_id: medical_program.id
      )

      params =
        division
        |> prepare_reimbursement_params(medical_program)
        |> Map.merge(%{
          "contractor_owner_id" => owner.id,
          "contract_number" => contract_number
        })
        |> Map.drop(~w(start_date end_date))

      err_message =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> post(contract_request_path(conn, :create, @path_type, contract_request.id), signed_content_params(params))
        |> json_response(409)
        |> get_in(~w(error message))

      assert "Invalid contract_request id" == err_message
    end

    test "invalid previous contract type", %{conn: conn} do
      %{
        medical_program: medical_program,
        legal_entity: legal_entity,
        division: division,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      contract_number = NumberGenerator.generate_from_sequence(1, 1)

      insert(
        :prm,
        :capitation_contract,
        contract_number: contract_number,
        status: ReimbursementContract.status(:verified),
        contractor_legal_entity: legal_entity
      )

      params =
        division
        |> prepare_reimbursement_params(medical_program)
        |> Map.merge(%{
          "contractor_owner_id" => owner.id,
          "contract_number" => contract_number
        })
        |> Map.drop(~w(start_date end_date))

      expect_signed_content(params, %{
        edrpou: legal_entity.edrpou,
        drfo: party_user.party.tax_id,
        surname: party_user.party.last_name
      })

      reason =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> post(contract_request_path(conn, :create, @path_type, UUID.generate()), signed_content_params(params))
        |> json_response(409)
        |> get_in(~w(error message))

      assert "Submitted contract type does not correspond to previously created content" == reason
    end

    test "invalid legal_entity client_type", %{conn: conn} do
      %{
        medical_program: medical_program,
        legal_entity: legal_entity,
        division: division,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data(@msp)

      params =
        division
        |> prepare_reimbursement_params(medical_program)
        |> Map.merge(%{
          "contractor_owner_id" => owner.id,
          "contractor_legal_entity_id" => legal_entity.id
        })
        |> Map.drop(~w(start_date end_date))

      expect_signed_content(params, %{
        edrpou: legal_entity.edrpou,
        drfo: party_user.party.tax_id,
        surname: party_user.party.last_name
      })

      reason =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> post(
          contract_request_path(conn, :create, @path_type, UUID.generate()),
          signed_content_params(params)
        )
        |> json_response(409)
        |> get_in(~w(error message))

      assert "Contract type \"#{@reimbursement}\" is not allowed for legal_entity with type \"#{@msp}\"" == reason
    end

    test "invalid contract_type in payload", %{conn: conn} do
      %{
        medical_program: medical_program,
        legal_entity: legal_entity,
        division: division,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      contract_number = NumberGenerator.generate_from_sequence(1, 1)

      insert(
        :prm,
        :reimbursement_contract,
        contract_number: contract_number,
        status: ReimbursementContract.status(:verified),
        contractor_legal_entity: legal_entity,
        medical_program_id: medical_program.id
      )

      params =
        division
        |> prepare_reimbursement_params(medical_program)
        |> Map.merge(%{
          "type" => "capitation",
          "contractor_owner_id" => owner.id,
          "contract_number" => contract_number
        })
        |> Map.drop(~w(start_date end_date))

      expect_signed_content(params, %{
        edrpou: legal_entity.edrpou,
        drfo: party_user.party.tax_id,
        surname: party_user.party.last_name
      })

      resp =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> post(contract_request_path(conn, :create, @path_type, UUID.generate()), signed_content_params(params))
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.type"
                 }
               ]
             } = resp["error"]
    end
  end

  describe "create reimbursement contract when medical program is invalid" do
    test "program id not match with previously created request", %{conn: conn} do
      %{
        medical_program: medical_program,
        legal_entity: legal_entity,
        division: division,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      contract_number = NumberGenerator.generate_from_sequence(1, 1)

      insert(
        :prm,
        :reimbursement_contract,
        contract_number: contract_number,
        status: ReimbursementContract.status(:verified),
        contractor_legal_entity: legal_entity,
        medical_program_id: medical_program.id
      )

      another_medical_program = insert(:prm, :medical_program)

      params =
        division
        |> prepare_reimbursement_params(another_medical_program)
        |> Map.merge(%{
          "contractor_owner_id" => owner.id,
          "contract_number" => contract_number
        })
        |> Map.drop(~w(start_date end_date))

      expect_signed_content(params, %{
        edrpou: legal_entity.edrpou,
        drfo: party_user.party.tax_id,
        surname: party_user.party.last_name
      })

      reason =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> post(contract_request_path(conn, :create, @path_type, UUID.generate()), signed_content_params(params))
        |> json_response(409)
        |> get_in(~w(error message))

      assert "Submitted medical_program_id does not correspond to previously created content" == reason
    end

    test "medical program not exist", %{conn: conn} do
      %{
        legal_entity: legal_entity,
        division: division,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      params =
        division
        |> prepare_reimbursement_params(legal_entity)
        |> Map.put("contractor_owner_id", owner.id)

      expect_signed_content(params, %{
        edrpou: legal_entity.edrpou,
        drfo: party_user.party.tax_id,
        surname: party_user.party.last_name
      })

      assert [err] =
               conn
               |> put_client_id_header(legal_entity.id)
               |> put_consumer_id_header(user_id)
               |> put_req_header("drfo", legal_entity.edrpou)
               |> post(contract_request_path(conn, :create, @path_type, UUID.generate()), signed_content_params(params))
               |> json_response(422)
               |> get_in(~w(error invalid))

      assert "Reimbursement program with such id does not exist" == hd(err["rules"])["description"]
    end

    test "medical program inactive", %{conn: conn} do
      medical_program = insert(:prm, :medical_program, is_active: false)

      %{
        legal_entity: legal_entity,
        division: division,
        user_id: user_id,
        owner: owner,
        party_user: party_user
      } = prepare_data()

      params =
        division
        |> prepare_reimbursement_params(medical_program)
        |> Map.put("contractor_owner_id", owner.id)

      expect_signed_content(params, %{
        edrpou: legal_entity.edrpou,
        drfo: party_user.party.tax_id,
        surname: party_user.party.last_name
      })

      reason =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> post(contract_request_path(conn, :create, @path_type, UUID.generate()), signed_content_params(params))
        |> json_response(409)
        |> get_in(~w(error message))

      assert "Reimbursement program is not active" == reason
    end
  end

  describe "update reimbursement contract request" do
    test "successful update", %{conn: conn} do
      employee = insert(:prm, :employee)

      contract_request =
        insert(
          :il,
          :reimbursement_contract_request,
          status: @in_process,
          start_date: Date.add(Date.utc_today(), 10),
          contractor_owner_id: employee.id
        )

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      legal_entity = insert(:prm, :legal_entity)

      params = %{
        "nhs_signer_base" => "на підставі наказу",
        "nhs_payment_method" => "prepayment"
      }

      conn
      |> put_client_id_header(legal_entity.id)
      |> patch(contract_request_path(conn, :update, @path_type, contract_request.id), params)
      |> json_response(200)
      |> Map.get("data")
      |> assert_show_response_schema("contract_request/reimbursement", "contract_request")
    end
  end

  describe "sign reimbursement contract MSP" do
    test "no contract_request found", %{conn: conn} do
      pharmacy()

      assert conn
             |> put_client_id_header(UUID.generate())
             |> patch(contract_request_path(conn, :sign_msp, @path_type, UUID.generate()))
             |> json_response(404)
    end

    test "invalid client_id", %{conn: conn} do
      msp()

      contract_request =
        insert(:il, :reimbursement_contract_request, status: ReimbursementContractRequest.status(:nhs_signed))

      legal_entity = insert(:prm, :legal_entity, type: @pharmacy)
      conn = put_client_id_header(conn, legal_entity.id)

      assert resp =
               conn
               |> patch(contract_request_path(conn, :sign_msp, @path_type, contract_request.id), %{
                 "signed_content" => "",
                 "signed_content_encoding" => "base64"
               })
               |> json_response(403)

      assert "Invalid client_id" == resp["error"]["message"]
    end

    test "contract_request already signed", %{conn: conn} do
      nhs()

      %{"client_id" => client_id, "user_id" => user_id, "contract_request" => contract_request} =
        prepare_nhs_sign_params(status: ReimbursementContractRequest.status(:signed))

      assert resp =
               conn
               |> put_client_id_header(client_id)
               |> put_consumer_id_header(user_id)
               |> patch(contract_request_path(conn, :sign_msp, @path_type, contract_request.id), %{
                 "signed_content" => "",
                 "signed_content_encoding" => "base64"
               })
               |> json_response(422)

      assert_error(resp, "Incorrect status for signing")
    end

    test "failed to decode signed content", %{conn: conn} do
      nhs()
      invalid_signed_content()

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "party_user" => party_user
      } = prepare_nhs_sign_params(status: ReimbursementContractRequest.status(:nhs_signed))

      assert resp =
               conn
               |> put_client_id_header(client_id)
               |> put_consumer_id_header(user_id)
               |> put_req_header("msp_drfo", party_user.party.tax_id)
               |> patch(contract_request_path(conn, :sign_msp, @path_type, contract_request.id), %{
                 "signed_content" => "invalid",
                 "signed_content_encoding" => "base64"
               })
               |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.signed_content",
                   "entry_type" => "json_data_property",
                   "rules" => [
                     %{
                       "description" => "Not a base64 string",
                       "params" => [],
                       "rule" => "invalid"
                     }
                   ]
                 }
               ],
               "type" => "validation_failed"
             } = resp["error"]
    end

    test "legal entity edrpou does not match with signer drfo", %{conn: conn} do
      insert(:il, :dictionary, name: "SETTLEMENT_TYPE", values: %{})
      insert(:il, :dictionary, name: "STREET_TYPE", values: %{})
      insert(:il, :dictionary, name: "SPECIALITY_TYPE", values: %{})
      nhs()

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "legal_entity" => legal_entity,
        "party_user" => party_user
      } = prepare_nhs_sign_params(status: ReimbursementContractRequest.status(:nhs_signed))

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("msp_drfo", legal_entity.edrpou)

      data = %{"id" => contract_request.id, "printout_content" => "<html></html>"}

      drfo_signed_content(data, [
        %{drfo: party_user.party.tax_id, surname: party_user.party.last_name},
        %{drfo: nil, surname: nil},
        %{drfo: legal_entity.edrpou, surname: party_user.party.last_name, is_stamp: true}
      ])

      resp =
        conn
        |> patch(contract_request_path(conn, :sign_msp, @path_type, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.drfo"
                 }
               ]
             } = resp["error"]
    end

    test "party last_name does not match with signer surname", %{conn: conn} do
      insert(:il, :dictionary, name: "SETTLEMENT_TYPE", values: %{})
      insert(:il, :dictionary, name: "STREET_TYPE", values: %{})
      insert(:il, :dictionary, name: "SPECIALITY_TYPE", values: %{})
      nhs()

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "legal_entity" => legal_entity,
        "nhs_signer" => nhs_signer
      } = prepare_nhs_sign_params(status: ReimbursementContractRequest.status(:nhs_signed))

      data = %{"id" => contract_request.id, "printout_content" => "<html></html>"}

      expect_signed_content(data, [
        %{
          edrpou: legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: "Підписант"
        },
        %{
          edrpou: nhs_signer.legal_entity.edrpou,
          drfo: nhs_signer.legal_entity.edrpou,
          surname: nhs_signer.party.last_name
        },
        %{
          edrpou: legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: "Підписант",
          is_stamp: true
        }
      ])

      assert resp =
               conn
               |> put_client_id_header(client_id)
               |> put_consumer_id_header(user_id)
               |> put_req_header("msp_drfo", legal_entity.edrpou)
               |> patch(contract_request_path(conn, :sign_msp, @path_type, contract_request.id), %{
                 "signed_content" => data |> Poison.encode!() |> Base.encode64(),
                 "signed_content_encoding" => "base64"
               })
               |> json_response(422)

      assert %{
               "invalid" => [
                 %{
                   "entry" => "$.last_name",
                   "rules" => [
                     %{
                       "description" => "Signer surname does not match with current user last_name"
                     }
                   ]
                 }
               ]
             } = resp["error"]
    end

    test "content doesn't match", %{conn: conn} do
      insert(:il, :dictionary, name: "SETTLEMENT_TYPE", values: %{})
      insert(:il, :dictionary, name: "STREET_TYPE", values: %{})
      insert(:il, :dictionary, name: "SPECIALITY_TYPE", values: %{})
      nhs()

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "legal_entity" => legal_entity,
        "contractor_owner_id" => employee_owner,
        "nhs_signer" => nhs_signer
      } = prepare_nhs_sign_params(status: ReimbursementContractRequest.status(:nhs_signed))

      data = %{"id" => contract_request.id, "printout_content" => "<html></html>"}

      expect_signed_content(data, [
        %{
          edrpou: legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: employee_owner.party.last_name
        },
        %{
          edrpou: nhs_signer.legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: nhs_signer.party.last_name
        },
        %{
          edrpou: nhs_signer.legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: nhs_signer.party.last_name,
          is_stamp: true
        }
      ])

      resp =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("msp_drfo", legal_entity.edrpou)
        |> patch(contract_request_path(conn, :sign_msp, @path_type, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(422)

      assert_error(resp, "Signed content does not match the previously created content")
    end

    test "failed to save signed content", %{conn: conn} do
      nhs()

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:error, "failed to save content"}
      end)

      id = UUID.generate()

      data = %{
        "id" => id,
        "printout_content" => nil,
        "status" => ReimbursementContractRequest.status(:nhs_signed)
      }

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "legal_entity" => legal_entity,
        "contractor_owner_id" => employee_owner,
        "nhs_signer" => nhs_signer
      } =
        prepare_nhs_sign_params(
          id: id,
          data: data,
          status: ReimbursementContractRequest.status(:nhs_signed)
        )

      expect_signed_content(data, [
        %{
          edrpou: legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: employee_owner.party.last_name
        },
        %{
          edrpou: nhs_signer.legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: nhs_signer.party.last_name
        },
        %{
          edrpou: nhs_signer.legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: nhs_signer.party.last_name,
          is_stamp: true
        }
      ])

      resp =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("msp_drfo", legal_entity.edrpou)
        |> patch(contract_request_path(conn, :sign_msp, @path_type, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(502)

      assert "Failed to save signed content" == resp["error"]["message"]
    end

    test "failed to create contract", %{conn: conn} do
      nhs()

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      id = UUID.generate()

      data = %{
        "id" => id,
        "printout_content" => nil,
        "status" => ReimbursementContractRequest.status(:nhs_signed)
      }

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "legal_entity" => legal_entity,
        "contractor_owner_id" => employee_owner,
        "nhs_signer" => nhs_signer
      } =
        prepare_nhs_sign_params(
          id: id,
          data: data,
          status: ReimbursementContractRequest.status(:nhs_signed)
        )

      expect_signed_content(data, [
        %{
          edrpou: legal_entity.edrpou,
          drfo: employee_owner.party.tax_id,
          surname: employee_owner.party.last_name
        },
        %{
          edrpou: nhs_signer.legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: nhs_signer.party.last_name
        },
        %{
          edrpou: nhs_signer.legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: nhs_signer.party.last_name,
          is_stamp: true
        }
      ])

      assert conn
             |> put_client_id_header(client_id)
             |> put_consumer_id_header(user_id)
             |> put_req_header("msp_drfo", legal_entity.edrpou)
             |> patch(contract_request_path(conn, :sign_msp, @path_type, contract_request.id), %{
               "signed_content" => data |> Poison.encode!() |> Base.encode64(),
               "signed_content_encoding" => "base64"
             })
             |> json_response(502)
    end

    test "nhs_legal_entity does not exists", %{conn: conn} do
      nhs()

      id = UUID.generate()

      data = %{
        "id" => id,
        "printout_content" => nil,
        "status" => ReimbursementContractRequest.status(:nhs_signed)
      }

      client_id = UUID.generate()
      legal_entity = insert(:prm, :legal_entity, type: @pharmacy, id: client_id)

      nhs_signer = insert(:prm, :employee)

      user_id = UUID.generate()

      division =
        insert(
          :prm,
          :division,
          legal_entity: legal_entity,
          phones: [%{"type" => "MOBILE", "number" => "+380631111111"}]
        )

      employee_owner =
        insert(
          :prm,
          :employee,
          id: user_id,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:owner)
        )

      now = Date.utc_today()
      start_date = Date.add(now, 10)

      params = [
        id: id,
        data: data,
        status: ReimbursementContractRequest.status(:nhs_signed),
        contract_number: "1345",
        nhs_signed_date: Date.utc_today(),
        nhs_signer_id: nhs_signer.id,
        nhs_legal_entity_id: UUID.generate(),
        contractor_legal_entity_id: client_id,
        contractor_owner_id: employee_owner.id,
        contractor_divisions: [division.id],
        start_date: start_date
      ]

      contract_request = insert(:il, :reimbursement_contract_request, params)

      expect_signed_content(data, [
        %{
          edrpou: legal_entity.edrpou,
          drfo: employee_owner.party.tax_id,
          surname: employee_owner.party.last_name
        },
        %{
          edrpou: legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: nhs_signer.party.last_name
        },
        %{
          edrpou: legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: nhs_signer.party.last_name,
          is_stamp: true
        }
      ])

      resp =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("msp_drfo", legal_entity.edrpou)
        |> patch(contract_request_path(conn, :sign_msp, @path_type, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(409)

      assert "NHS legal entity not found" == resp["error"]["message"]
    end

    test "nhs employee does not exists", %{conn: conn} do
      nhs()

      id = UUID.generate()

      data = %{
        "id" => id,
        "printout_content" => nil,
        "status" => ReimbursementContractRequest.status(:nhs_signed)
      }

      client_id = UUID.generate()
      legal_entity = insert(:prm, :legal_entity, type: @pharmacy, id: client_id)
      nhs_legal_entity = insert(:prm, :legal_entity)

      user_id = UUID.generate()
      party_user = insert(:prm, :party_user, user_id: user_id)

      division =
        insert(
          :prm,
          :division,
          legal_entity: legal_entity,
          phones: [%{"type" => "MOBILE", "number" => "+380631111111"}]
        )

      employee_owner =
        insert(
          :prm,
          :employee,
          id: user_id,
          party: party_user.party,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:owner)
        )

      nhs_signer =
        insert(
          :prm,
          :employee,
          party: party_user.party,
          legal_entity: nhs_legal_entity
        )

      now = Date.utc_today()
      start_date = Date.add(now, 10)

      params = %{
        id: id,
        data: data,
        status: ReimbursementContractRequest.status(:nhs_signed),
        contract_number: "1345",
        nhs_signed_date: Date.utc_today(),
        nhs_signer_id: UUID.generate(),
        nhs_legal_entity_id: nhs_legal_entity.id,
        contractor_legal_entity_id: client_id,
        contractor_owner_id: employee_owner.id,
        contractor_divisions: [division.id],
        start_date: start_date
      }

      contract_request = insert(:il, :reimbursement_contract_request, params)

      expect_signed_content(data, [
        %{
          edrpou: legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: employee_owner.party.last_name
        },
        %{
          edrpou: nhs_signer.legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: nhs_signer.party.last_name
        },
        %{
          edrpou: nhs_signer.legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: nhs_signer.party.last_name,
          is_stamp: true
        }
      ])

      resp =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("msp_drfo", legal_entity.edrpou)
        |> patch(contract_request_path(conn, :sign_msp, @path_type, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(409)

      assert "NHS employee not found" == resp["error"]["message"]
    end

    test "nhs signer edrpou does not match with nhs legal entity edrpou", %{conn: conn} do
      nhs()

      id = UUID.generate()

      data = %{
        "id" => id,
        "printout_content" => nil,
        "status" => ReimbursementContractRequest.status(:nhs_signed)
      }

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "legal_entity" => legal_entity,
        "contractor_owner_id" => employee_owner,
        "nhs_signer" => nhs_signer
      } =
        prepare_nhs_sign_params(
          id: id,
          data: data,
          status: ReimbursementContractRequest.status(:nhs_signed),
          contract_number: "1345"
        )

      expect_signed_content(data, [
        %{
          edrpou: legal_entity.edrpou,
          drfo: legal_entity.edrpou,
          surname: employee_owner.party.last_name
        },
        %{
          edrpou: legal_entity.edrpou,
          drfo: legal_entity.edrpou,
          surname: nhs_signer.party.last_name
        },
        %{
          edrpou: legal_entity.edrpou,
          drfo: legal_entity.edrpou,
          surname: employee_owner.party.last_name,
          is_stamp: true
        }
      ])

      resp =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("msp_drfo", legal_entity.edrpou)
        |> patch(contract_request_path(conn, :sign_msp, @path_type, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(422)

      assert [
               %{
                 "entry" => "$.drfo",
                 "rules" => [
                   %{
                     "description" => "Does not match the signer drfo"
                   }
                 ]
               }
             ] = resp["error"]["invalid"]
    end

    test "nhs signer surname does not match with nhs employee edrpou", %{conn: conn} do
      nhs()

      id = UUID.generate()

      data = %{
        "id" => id,
        "printout_content" => nil,
        "status" => ReimbursementContractRequest.status(:nhs_signed)
      }

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "legal_entity" => legal_entity,
        "contractor_owner_id" => employee_owner,
        "nhs_signer" => nhs_signer
      } =
        prepare_nhs_sign_params(
          id: id,
          data: data,
          status: ReimbursementContractRequest.status(:nhs_signed),
          contract_number: "1345"
        )

      expect_signed_content(data, [
        %{
          edrpou: legal_entity.edrpou,
          drfo: employee_owner.party.tax_id,
          surname: employee_owner.party.last_name
        },
        %{
          edrpou: nhs_signer.legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: "Чужий"
        },
        %{
          edrpou: nhs_signer.legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: "Чужий",
          is_stamp: true
        }
      ])

      resp =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("msp_drfo", legal_entity.edrpou)
        |> patch(contract_request_path(conn, :sign_msp, @path_type, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(422)

      assert [
               %{
                 "entry" => "$.last_name",
                 "entry_type" => "json_data_property",
                 "rules" => [
                   %{
                     "description" => "Signer surname does not match with current user last_name",
                     "params" => [],
                     "rule" => "invalid"
                   }
                 ]
               }
             ] == resp["error"]["invalid"]
    end

    test "stamp edrpou does not match nhs legal entity", %{conn: conn} do
      nhs()

      id = UUID.generate()

      data = %{
        "id" => id,
        "printout_content" => nil,
        "status" => ReimbursementContractRequest.status(:nhs_signed)
      }

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "legal_entity" => legal_entity,
        "contractor_owner_id" => employee_owner,
        "nhs_signer" => nhs_signer
      } =
        prepare_nhs_sign_params(
          id: id,
          data: data,
          status: ReimbursementContractRequest.status(:nhs_signed),
          contract_number: "1345"
        )

      conn =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("msp_drfo", legal_entity.edrpou)

      drfo_signed_content(data, [
        %{drfo: legal_entity.edrpou, surname: employee_owner.party.last_name},
        %{drfo: nhs_signer.legal_entity.edrpou, surname: nhs_signer.party.last_name},
        %{drfo: legal_entity.edrpou, surname: nhs_signer.party.last_name, is_stamp: true}
      ])

      resp =
        conn
        |> patch(contract_request_path(conn, :sign_msp, @path_type, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(422)

      assert [
               %{
                 "entry" => "$.drfo",
                 "rules" => [
                   %{
                     "description" => "Does not match the signer drfo"
                   }
                 ]
               }
             ] = resp["error"]["invalid"]
    end

    test "success to sign contract_request", %{conn: conn} do
      nhs()

      expect(MediaStorageMock, :store_signed_content, fn _, bucket, _, _, _ ->
        assert :contract_bucket == bucket
        {:ok, "success"}
      end)

      id = UUID.generate()

      data = %{
        "id" => id,
        "printout_content" => nil,
        "status" => ReimbursementContractRequest.status(:nhs_signed)
      }

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "contract_request" => contract_request,
        "legal_entity" => legal_entity,
        "contractor_owner_id" => employee_owner,
        "nhs_signer" => nhs_signer,
        "division" => %{id: division_id}
      } =
        prepare_nhs_sign_params(
          id: id,
          data: data,
          status: ReimbursementContractRequest.status(:nhs_signed),
          contract_number: "1345"
        )

      expect_signed_content(data, [
        %{
          edrpou: legal_entity.edrpou,
          drfo: employee_owner.party.tax_id,
          surname: employee_owner.party.last_name
        },
        %{
          edrpou: nhs_signer.legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: nhs_signer.party.last_name
        },
        %{
          edrpou: nhs_signer.legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: nhs_signer.party.last_name,
          is_stamp: true
        }
      ])

      resp_data =
        conn
        |> put_client_id_header(client_id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("msp_drfo", legal_entity.edrpou)
        |> patch(contract_request_path(conn, :sign_msp, @path_type, contract_request.id), %{
          "signed_content" => data |> Poison.encode!() |> Base.encode64(),
          "signed_content_encoding" => "base64"
        })
        |> json_response(200)
        |> Map.get("data")

      assert_show_response_schema(resp_data, "contract", "reimbursement_contract")

      assert %{division_id: ^division_id} = PRMRepo.get_by(ContractDivision, contract_id: resp_data["id"])
    end

    test "success to sign contract_request with existing parent_contract_id", %{conn: conn} do
      nhs()

      expect(MediaStorageMock, :store_signed_content, fn _, _, _, _, _ ->
        {:ok, "success"}
      end)

      id = UUID.generate()

      data = %{
        "id" => id,
        "printout_content" => nil,
        "status" => ReimbursementContractRequest.status(:nhs_signed)
      }

      contract = insert(:prm, :reimbursement_contract, contract_number: "1345")
      employee = insert(:prm, :employee)
      insert(:prm, :contract_employee, contract_id: contract.id, employee_id: employee.id)
      insert(:prm, :contract_division, contract_id: contract.id)

      %{
        "client_id" => client_id,
        "user_id" => user_id,
        "legal_entity" => legal_entity,
        "contract_request" => contract_request,
        "contractor_owner_id" => employee_owner,
        "nhs_signer" => nhs_signer
      } =
        prepare_nhs_sign_params(
          id: id,
          data: data,
          status: ReimbursementContractRequest.status(:nhs_signed),
          contract_number: "1345",
          parent_contract_id: contract.id
        )

      expect_signed_content(data, [
        %{
          edrpou: legal_entity.edrpou,
          drfo: employee_owner.party.tax_id,
          surname: employee_owner.party.last_name
        },
        %{
          edrpou: nhs_signer.legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: nhs_signer.party.last_name
        },
        %{
          edrpou: nhs_signer.legal_entity.edrpou,
          drfo: nhs_signer.party.tax_id,
          surname: nhs_signer.party.last_name,
          is_stamp: true
        }
      ])

      conn
      |> put_client_id_header(client_id)
      |> put_consumer_id_header(user_id)
      |> put_req_header("msp_drfo", legal_entity.edrpou)
      |> patch(contract_request_path(conn, :sign_msp, @path_type, contract_request.id), %{
        "signed_content" => data |> Poison.encode!() |> Base.encode64(),
        "signed_content_encoding" => "base64"
      })
      |> json_response(200)
      |> Map.get("data")
      |> assert_show_response_schema("contract", "reimbursement_contract")
    end
  end

  describe "decline contract_request" do
    test "success decline contract request and event manager registration", %{conn: conn} do
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
          employee_type: Employee.type(:pharmacy_owner),
          party: party_user.party
        )

      insert(:prm, :division, legal_entity: legal_entity)

      contract_request =
        insert(
          :il,
          :reimbursement_contract_request,
          status: @in_process,
          nhs_signer_id: employee_owner.id,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee_owner.id
        )

      expect(MithrilMock, :get_user_roles, fn _, _, _ ->
        {:ok, %{"data" => [%{"role_name" => "NHS ADMIN SIGNER"}]}}
      end)

      data = %{
        "id" => contract_request.id,
        "next_status" => "DECLINED",
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "status_reason" => "Не відповідає попереднім домовленостям",
        "text" => "something"
      }

      expect_signed_content(data, %{
        edrpou: legal_entity.edrpou,
        drfo: party_user.party.tax_id,
        surname: party_user.party.last_name
      })

      resp_data =
        conn
        |> put_client_id_header(legal_entity.id)
        |> put_consumer_id_header(user_id)
        |> put_req_header("drfo", legal_entity.edrpou)
        |> patch(contract_request_path(conn, :decline, @path_type, contract_request.id), signed_content_params(data))
        |> json_response(200)
        |> Map.get("data")
        |> assert_show_response_schema("contract_request/reimbursement", "contract_request")

      assert resp_data["status"] == ReimbursementContractRequest.status(:declined)

      contract_request = Core.Repo.get(ReimbursementContractRequest, contract_request.id)
      assert contract_request.status_reason == "Не відповідає попереднім домовленостям"
      assert contract_request.nhs_signer_id == user_id
      assert contract_request.nhs_legal_entity_id == legal_entity.id

      contract_request_id = contract_request.id
      contract_request_status = contract_request.status
      assert event = EventManagerRepo.one(Event)

      assert %Event{
               entity_type: "ReimbursementContractRequest",
               event_type: "StatusChangeEvent",
               entity_id: ^contract_request_id,
               changed_by: ^user_id,
               properties: %{"status" => %{"new_value" => ^contract_request_status}}
             } = event
    end
  end

  describe "approve contract_request" do
    setup %{conn: conn} do
      insert(:il, :dictionary, name: "SETTLEMENT_TYPE", values: %{})
      insert(:il, :dictionary, name: "STREET_TYPE", values: %{})
      insert(:il, :dictionary, name: "SPECIALITY_TYPE", values: %{})

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
        insert(:prm, :employee,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:pharmacy_owner),
          party: party_user.party
        )

      division =
        insert(:prm, :division, legal_entity: legal_entity, phones: [%{"type" => "MOBILE", "number" => "+380631111111"}])

      %{
        conn: conn,
        user_id: user_id,
        party_user: party_user,
        legal_entity: legal_entity,
        employee_owner: employee_owner,
        division: division
      }
    end

    test "success", %{conn: conn, legal_entity: legal_entity, party_user: party_user} = context do
      contract_request =
        insert(
          :il,
          :reimbursement_contract_request,
          status: @in_process,
          nhs_signer_id: context.employee_owner.id,
          nhs_legal_entity_id: legal_entity.id,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: context.employee_owner.id,
          contractor_divisions: [context.division.id],
          start_date: contract_start_date()
        )

      data = %{
        "id" => contract_request.id,
        "next_status" => "APPROVED",
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "text" => "something"
      }

      expect_signed_content(data, %{
        edrpou: legal_entity.edrpou,
        drfo: party_user.party.tax_id,
        surname: party_user.party.last_name
      })

      conn
      |> put_client_id_header(legal_entity.id)
      |> put_consumer_id_header(context.user_id)
      |> put_req_header("drfo", legal_entity.edrpou)
      |> patch(contract_request_path(conn, :approve, @path_type, contract_request.id), signed_content_params(data))
      |> json_response(200)
      |> Map.get("data")
      |> assert_show_response_schema("contract_request/reimbursement", "contract_request")
    end

    test "fail on medication_program is not active",
         %{conn: conn, legal_entity: legal_entity, party_user: party_user} = context do
      %{id: medical_program_id} = insert(:prm, :medical_program, is_active: false)

      contract_request =
        insert(
          :il,
          :reimbursement_contract_request,
          status: @in_process,
          nhs_signer_id: context.employee_owner.id,
          nhs_legal_entity_id: legal_entity.id,
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: context.employee_owner.id,
          contractor_divisions: [context.division.id],
          medical_program_id: medical_program_id,
          start_date: contract_start_date()
        )

      data = %{
        "id" => contract_request.id,
        "next_status" => "APPROVED",
        "contractor_legal_entity" => %{
          "id" => contract_request.contractor_legal_entity_id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        },
        "text" => "something"
      }

      expect_signed_content(data, %{
        edrpou: legal_entity.edrpou,
        drfo: party_user.party.tax_id,
        surname: party_user.party.last_name
      })

      assert conn
             |> put_client_id_header(legal_entity.id)
             |> put_consumer_id_header(context.user_id)
             |> put_req_header("drfo", legal_entity.edrpou)
             |> patch(
               contract_request_path(conn, :approve, @path_type, contract_request.id),
               signed_content_params(data)
             )
             |> json_response(409)
    end
  end

  describe "approve contract_request by msp" do
    test "success", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, type: @pharmacy)

      employee_owner =
        insert(:prm, :employee, legal_entity_id: legal_entity.id, employee_type: Employee.type(:pharmacy_owner))

      division =
        insert(
          :prm,
          :division,
          legal_entity: legal_entity,
          phones: [%{"type" => "MOBILE", "number" => "+380631111111"}]
        )

      now = Date.utc_today()
      start_date = Date.add(now, 10)

      contract_request =
        insert(
          :il,
          :reimbursement_contract_request,
          status: ReimbursementContractRequest.status(:approved),
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee_owner.id,
          contractor_divisions: [division.id],
          start_date: start_date
        )

      conn
      |> put_client_id_header(legal_entity.id)
      |> put_consumer_id_header()
      |> patch(contract_request_path(conn, :approve_msp, @path_type, contract_request.id))
      |> json_response(200)
      |> Map.get("data")
      |> assert_show_response_schema("contract_request/reimbursement", "contract_request")
    end

    test "fails on inactive medical program", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, type: @pharmacy)

      employee_owner =
        insert(:prm, :employee, legal_entity_id: legal_entity.id, employee_type: Employee.type(:pharmacy_owner))

      division =
        insert(
          :prm,
          :division,
          legal_entity: legal_entity,
          phones: [%{"type" => "MOBILE", "number" => "+380631111111"}]
        )

      now = Date.utc_today()
      start_date = Date.add(now, 10)
      %{id: medical_program_id} = insert(:prm, :medical_program, is_active: false)

      contract_request =
        insert(
          :il,
          :reimbursement_contract_request,
          status: ReimbursementContractRequest.status(:approved),
          contractor_legal_entity_id: legal_entity.id,
          contractor_owner_id: employee_owner.id,
          contractor_divisions: [division.id],
          start_date: start_date,
          medical_program_id: medical_program_id
        )

      assert %{"error" => error} =
               conn
               |> put_client_id_header(legal_entity.id)
               |> put_consumer_id_header()
               |> patch(contract_request_path(conn, :approve_msp, @path_type, contract_request.id))
               |> json_response(409)

      assert "Reimbursement program is not active" == error["message"]
    end
  end

  describe "get printout_form" do
    test "success get printout_form", %{conn: conn} do
      nhs()
      template()
      insert(:il, :dictionary, name: "SETTLEMENT_TYPE", values: %{})
      insert(:il, :dictionary, name: "STREET_TYPE", values: %{})
      insert(:il, :dictionary, name: "SPECIALITY_TYPE", values: %{})
      insert(:il, :dictionary, name: "MEDICAL_SERVICE", values: %{})

      %{id: id} = insert(:il, :reimbursement_contract_request, status: @pending_nhs_sign)

      resp =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(contract_request_path(conn, :printout_content, @path_type, id))
        |> json_response(200)

      assert %{"id" => id, "printout_content" => "<html></html>"} == resp["data"]
    end

    test "fails on invalid status", %{conn: conn} do
      client_id = UUID.generate()
      contract_request = insert(:il, :reimbursement_contract_request, contractor_legal_entity_id: client_id)
      pharmacy()

      conn =
        conn
        |> put_client_id_header(client_id)
        |> get(contract_request_path(conn, :printout_content, @path_type, contract_request.id))

      assert json_response(conn, 409)
    end

    test "fails on MSP client type", %{conn: conn} do
      contract_request = insert(:il, :reimbursement_contract_request)
      msp()

      conn =
        conn
        |> put_client_id_header(UUID.generate())
        |> get(contract_request_path(conn, :printout_content, @path_type, contract_request.id))

      assert json_response(conn, 403)
    end
  end

  describe "terminate contract_request" do
    test "success contract_request terminating", %{conn: conn} do
      pharmacy(4)
      user_id = UUID.generate()
      party_user = insert(:prm, :party_user, user_id: user_id)
      legal_entity = insert(:prm, :legal_entity)

      employee_owner =
        insert(
          :prm,
          :employee,
          legal_entity_id: legal_entity.id,
          employee_type: Employee.type(:pharmacy_owner),
          party: party_user.party
        )

      for status <- @allowed_statuses_for_termination do
        contract_request =
          insert(
            :il,
            :reimbursement_contract_request,
            status: status,
            nhs_signer_id: employee_owner.id,
            contractor_legal_entity_id: legal_entity.id,
            contractor_owner_id: employee_owner.id
          )

        resp =
          conn
          |> put_client_id_header(legal_entity.id)
          |> put_consumer_id_header(user_id)
          |> patch(contract_request_path(conn, :terminate, @path_type, contract_request.id), %{
            "status_reason" => "Неправильний період контракту"
          })
          |> json_response(200)
          |> Map.get("data")
          |> assert_show_response_schema("contract_request/reimbursement", "contract_request")

        assert resp["status"] == ReimbursementContractRequest.status(:terminated)
      end
    end
  end

  defp prepare_reimbursement_params(division, medical_program) do
    now = contract_start_date()
    start_date = Date.to_iso8601(now)
    end_date = Date.to_iso8601(Date.add(now, 30))

    %{
      "contractor_owner_id" => UUID.generate(),
      "contractor_base" => "на підставі закону про Медичне обслуговування населення",
      "contractor_payment_details" => %{
        "bank_name" => "Банк номер 1",
        "MFO" => "351005",
        "payer_account" => "32009102701026"
      },
      "id_form" => "5",
      "contractor_divisions" => [division.id],
      "start_date" => start_date,
      "end_date" => end_date,
      "statute_md5" => "media/upload_contract_request_statute.pdf",
      "additional_document_md5" => "media/upload_contract_request_additional_document.pdf",
      "medical_program_id" => medical_program.id,
      "consent_text" =>
        "Цією заявою Заявник висловлює бажання укласти договір про медичне обслуговування населення за програмою державних гарантій медичного обслуговування населення (далі – Договір) на умовах, визначених в оголошенні про укладення договорів про медичне обслуговування населення (далі – Оголошення). Заявник підтверджує, що: 1. на момент подання цієї заяви Заявник має чинну ліцензію на провадження господарської діяльності з медичної практики та відповідає ліцензійним умовам з медичної практики; 2. Заявник надає медичні послуги, пов’язані з первинною медичною допомогою (далі – ПМД); 3. Заявник зареєстрований в електронній системі охорони здоров’я (далі – Система); 4. уповноважені особи та медичні працівники, які будуть залучені до виконання Договору, зареєстровані в Системі та отримали електронний цифровий підпис (далі – ЕЦП); 5. в кожному місці надання медичних послуг Заявника наявне матеріально-технічне оснащення, передбачене розділом І Примірного табелю матеріально-технічного оснащення закладів охорони здоров’я та фізичних осіб – підприємців, які надають ПМД, затвердженого наказом Міністерства охорони здоров’я України від 26 січня 2018 року № 148; 6. установчими або іншими документами не обмежено право керівника Заявника підписувати договори від імені Заявника без попереднього погодження власника. Якщо таке право обмежено, у тому числі щодо укладання договорів, ціна яких перевищує встановлену суму, Заявник повідомить про це Національну службу здоров’я та отримає необхідні погодження від власника до моменту підписання договору зі сторони Заявника; 7. інформація, зазначена Заявником у цій Заяві та доданих до неї документах, а також інформація, внесена Заявником (його уповноваженими особами) до Системи, є повною та достовірною. Заявник усвідомлює, що у разі зміни інформації, зазначеної Заявником у цій заяві та (або) доданих до неї документах Заявник зобов’язаний повідомити про такі зміни НСЗУ протягом трьох робочих днів з дня настання таких змін шляхом надсилання інформації про такі зміни на електронну пошту dohovir@nszu.gov.ua, з одночасним внесенням таких змін в Систему. Заявник усвідомлює, що законодавством України передбачена відповідальність за подання недостовірної інформації органам державної влади."
    }
  end

  defp prepare_data(legal_entity_type \\ @pharmacy) do
    user_id = UUID.generate()
    party_user = insert(:prm, :party_user, user_id: user_id)
    legal_entity = insert(:prm, :legal_entity, type: legal_entity_type)
    medical_program = insert(:prm, :medical_program)

    division =
      insert(
        :prm,
        :division,
        legal_entity: legal_entity,
        phones: [%{"type" => "MOBILE", "number" => "+380631111111"}]
      )

    owner =
      insert(
        :prm,
        :employee,
        employee_type: Employee.type(:pharmacy_owner),
        party: party_user.party,
        legal_entity_id: legal_entity.id
      )

    %{
      legal_entity: legal_entity,
      medical_program: medical_program,
      division: division,
      user_id: user_id,
      owner: owner,
      party_user: party_user
    }
  end

  defp signed_content_params(content) do
    %{
      "signed_content" => content |> Jason.encode!() |> Base.encode64(),
      "signed_content_encoding" => "base64"
    }
  end

  defp prepare_nhs_sign_params(contract_request_params, legal_entity_params \\ []) do
    client_id = UUID.generate()
    params = Keyword.merge([id: client_id, type: "PHARMACY"], legal_entity_params)
    legal_entity = insert(:prm, :legal_entity, params)
    nhs_legal_entity = insert(:prm, :legal_entity)

    user_id = UUID.generate()
    party_user = insert(:prm, :party_user, user_id: user_id)

    nhs_signer =
      insert(
        :prm,
        :employee,
        party: party_user.party,
        legal_entity: nhs_legal_entity
      )

    division =
      insert(
        :prm,
        :division,
        legal_entity: legal_entity,
        phones: [%{"type" => "MOBILE", "number" => "+380631111111"}]
      )

    employee_owner =
      insert(
        :prm,
        :employee,
        id: user_id,
        party: party_user.party,
        legal_entity_id: legal_entity.id,
        employee_type: Employee.type(:pharmacy_owner)
      )

    now = Date.utc_today()
    start_date = Date.add(now, 10)

    %{id: medical_program_id} = insert(:prm, :medical_program)

    params =
      Keyword.merge(
        [
          nhs_signed_date: Date.utc_today(),
          nhs_signer_id: nhs_signer.id,
          nhs_legal_entity_id: nhs_legal_entity.id,
          contractor_legal_entity_id: client_id,
          contractor_owner_id: employee_owner.id,
          contractor_divisions: [division.id],
          medical_program_id: medical_program_id,
          start_date: start_date
        ],
        contract_request_params
      )

    contract_request = insert(:il, :reimbursement_contract_request, params)

    %{
      "client_id" => client_id,
      "user_id" => user_id,
      "legal_entity" => legal_entity,
      "contract_request" => contract_request,
      "contractor_owner_id" => employee_owner,
      "nhs_signer" => nhs_signer,
      "party_user" => party_user,
      "division" => division
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

  defp contract_start_date() do
    Date.add(Date.utc_today(), 1)
  end
end
