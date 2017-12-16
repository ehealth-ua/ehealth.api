defmodule EHealth.Integraiton.DeclarationRequest.API.SignTest do
  @moduledoc false

  alias EHealth.Repo
  use EHealth.Web.ConnCase
  import EHealth.DeclarationRequest.API.Sign
  alias EHealth.DeclarationRequest

  describe "check_status/2" do
    test "raises error when id is invalid" do
      assert_raise(Ecto.Query.CastError, fn ->
        check_status({:ok, "somedata"}, %{"id" => "111"})
      end)
    end

    test "raises error when id does not exist" do
      assert_raise(Ecto.NoResultsError, fn ->
        check_status({:ok, "somedata"}, %{"id" => Ecto.UUID.generate()})
      end)
    end

    test "returns error when status is not APPROVED" do
      %DeclarationRequest{id: id} = simple_fixture(:declaration_request)
      result = check_status({:ok, "somedata"}, %{"id" => id})
      expected_result = {:error, [{%{description: "incorrect status", params: [], rule: :invalid}, "$.status"}]}
      assert expected_result == result
    end

    test "returns expected result when status is APPROVED" do
      declaration_request = %DeclarationRequest{id: id} = simple_fixture(:declaration_request, "APPROVED")
      assert {:ok, "somedata", declaration_request} == check_status({:ok, "somedata"}, %{"id" => id})
    end
  end

  describe "check_patient_signed/1" do
    test "returns error when content is empty" do
      db_data = %DeclarationRequest{data: %{"person" => %{"key" => "another_value"}}}
      input_data = %{"data" => %{"content" => ""}}
      result = check_patient_signed({:ok, input_data, db_data})
      expected_result = {:error, [{%{description: "Can not be empty",
        params: [], rule: :invalid}, "$.declaration_request"}]}
      assert expected_result == result
    end

    test "returns error when patient_signed is false" do
      db_data = %DeclarationRequest{data: %{"person" => %{"key" => "another_value"}}}
      input_data = %{"data" => %{"content" => %{"person" => %{"key" => "value", "patient_signed" => false}}}}
      result = check_patient_signed({:ok, input_data, db_data})
      expected_result = {:error, [{%{description: "Patient must sign declaration form",
        params: [], rule: :invalid}, "$.person.patient_signed"}]}
      assert expected_result == result
    end

    test "returns expected result when patient_signed is true" do
      id = Ecto.UUID.generate()
      db_data = %DeclarationRequest{id: id, data: %{"person" => %{"key" => "value", "patient_signed" => false}},
        status: "APPROVED", printout_content: "<html></html>"}
      content = %{"id" => id, "person" => %{"key" => "value", "patient_signed" => true}, "status" => "APPROVED",
        "content" => "<html></html>"}
      input_data = %{"data" => %{"content" => content}}
      result = check_patient_signed({:ok, input_data, db_data})
      expected_result = {:ok, %{"data" => %{"content" => content}}, db_data}
      assert expected_result == result
    end
  end

  describe "compare_with_db/1" do
    test "returns error when data does not match" do
      db_data = %DeclarationRequest{data: %{"person" => %{"key" => "another_value"}}}
      input_data = %{"data" => %{"content" => %{"person" => %{"key" => "value"}}}}
      result = compare_with_db({:ok, input_data, db_data})
      expected_result = {:error, [{%{description: "Signed content does not match the previously created content",
        params: [], rule: :invalid}, "$.content"}]}
      assert expected_result == result
    end

    test "returns expected result when data matches" do
      id = Ecto.UUID.generate()
      db_data = %DeclarationRequest{
        id: id,
        data: %{
          "person" => %{"key" => "value", "patient_signed" => false},
          "seed" => "99bc78ba577a95a11f1a344d4d2ae55f2f857b98"
        },
        status: "APPROVED", printout_content: "<html></html>"
      }
      content = %{"id" => id, "person" => %{"key" => "value", "patient_signed" => true}, "status" => "APPROVED",
        "content" => "<html></html>", "seed" => "some_current_hash"}
      input_data = %{"data" => %{"content" => content}}
      result = compare_with_db({:ok, input_data, db_data})
      expected_result = {:ok, %{"data" => %{"content" => content}}, db_data}
      assert expected_result == result
    end
  end

  describe "check_drfo/1" do
    test "returns error when drfo does not match the tax_id" do
      employee = %{"party" => %{"tax_id" => "111"}}
      signer = %{"drfo" => "222"}
      input_data = %{"data" => %{"content" => %{"employee" => employee}, "signer" => signer}}
      result = check_drfo({:ok, input_data, %DeclarationRequest{}})
      expected_result = {:error, [{%{description: "Does not match the signer drfo",
        params: [], rule: :invalid}, "$.content.employee.party.tax_id"}]}
      assert expected_result == result
    end

    test "returns expected result when drfo matches the tax_id" do
      employee = %{"party" => %{"tax_id" => "AA111"}}
      signer = %{"drfo" => "AA 111"}
      input_data = %{"data" => %{"content" => %{"employee" => employee}, "signer" => signer}}
      result = check_drfo({:ok, input_data, %DeclarationRequest{}})
      expected_result = {:ok, {%{"employee" => employee}, %DeclarationRequest{}}}
      assert expected_result == result
    end
  end

  describe "check_employee_id/2" do
    defmodule PRMMock do
      use MicroservicesHelper

      Plug.Router.get "/party_users" do
        user_id = Map.get(conn.params, "user_id")

        party_users = [
          %{
            "user_id": user_id,
            "party_id": "d79afe28-2716-4ba6-8e6e-275c0697a1b9"
          },
          %{
            "user_id": user_id,
            "party_id": Ecto.UUID.generate()
          }
        ]

        send_resp(conn, 200, Poison.encode!(%{"data" => party_users}))
      end

      Plug.Router.get "/employees" do
        employees = [
          %{
            "id": Ecto.UUID.generate()
          },
          %{
            "id": "f1ee8ca3-b8ba-4fbe-b186-3c7d08f0f323"
          }
        ]

        send_resp(conn, 200, Poison.encode!(%{"data" => employees}))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(PRMMock)

      System.put_env("PRM_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("PRM_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      :ok
    end

    test "returns forbidden when you try to sign someone else's declaration" do
      content = %{"employee" => %{"id" => Ecto.UUID.generate()}}
      x_consumer_id_header = {"x-consumer-id", "88231792-f27f-4e5d-9f29-f246557ba42b"}
      assert {:error, :forbidden} == check_employee_id({:ok, {content, "somedata"}}, [x_consumer_id_header])
    end

    test "returns expected result when you sign your declaration" do
      user_id = "88231792-f27f-4e5d-9f29-f246557ba42b"
      id = "f1ee8ca3-b8ba-4fbe-b186-3c7d08f0f323"
      party = insert(:prm, :party)
      insert(:prm, :party_user, party: party, user_id: user_id)
      legal_entity = insert(:prm, :legal_entity, id: "88231792-f27f-4e5d-9f29-f246557ba42b")
      insert(:prm, :employee, id: id, legal_entity: legal_entity, party: party)
      content = %{"employee" => %{"id" => id}}
      x_consumer_id_header = {"x-consumer-id", user_id}
      assert {:ok, {content, "somedata"}} == check_employee_id({:ok, {content, "somedata"}}, [x_consumer_id_header])
    end
  end

  describe "create_or_update_person/2" do
    defmodule MPIMock do
      use MicroservicesHelper

      Plug.Router.post "/persons" do
        send_resp(conn, 200, Poison.encode!(conn.body_params))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(MPIMock)

      System.put_env("MPI_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("MPI_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      :ok
    end

    test "returns expected result" do
      declaration_request = simple_fixture(:declaration_request)
      person = %{"data" => "somedata", "patient_signed" => false}
      expected_result = {:ok, %{"data" => "somedata", "patient_signed" => true}, declaration_request}
      assert expected_result == create_or_update_person({:ok, {%{"person" => person}, declaration_request}}, [])
    end
  end

  describe "create_declaration_with_termination_logic/2" do
    defmodule OPSMock do
      use MicroservicesHelper

      Plug.Router.post "/declarations/with_termination" do
        %{"declaration_request_id" => _} = conn.body_params

        send_resp(conn, 200, Poison.encode!(%{data: conn.body_params}))
      end
    end

    setup do
      {:ok, port, ref} = start_microservices(OPSMock)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      :ok
    end

    test "returns expected result" do
      %DeclarationRequest{data: declaration_request_data} = declaration_request = simple_fixture(:declaration_request)
      person_id = Ecto.UUID.generate()
      person_data = %{"data" => %{"id" => person_id}}
      client_id = Ecto.UUID.generate()
      x_consumer_metadata_header = {"x-consumer-metadata", Poison.encode!(%{"client_id" => client_id})}
      {:ok, %{"data" => data}} = create_declaration_with_termination_logic({:ok, person_data, declaration_request},
        [x_consumer_metadata_header])
      assert client_id == data["created_by"]
      assert client_id == data["updated_by"]
      assert person_id == data["person_id"]
      assert declaration_request_data["division"]["id"] == data["division_id"]
      assert declaration_request_data["employee"]["id"] == data["employee_id"]
      assert declaration_request_data["legal_entity"]["id"] == data["legal_entity_id"]
      assert declaration_request_data["start_date"] == data["start_date"]
      assert declaration_request_data["end_date"] == data["end_date"]
      assert declaration_request_data["scope"] == data["scope"]
      assert declaration_request_data["seed"] == data["seed"]
      assert "active" == data["status"]
      assert data["is_active"]
    end

    test "returns active status when authentication_method_current.type == NA" do
      declaration_request = simple_fixture(:declaration_request, "ACTIVE", "NA")
      person_data = %{"data" => %{"id" => ""}}
      {:ok, %{"data" => data}} = create_declaration_with_termination_logic({:ok, person_data, declaration_request}, [])
      assert "active" == data["status"]
    end

    test "returns pending_validation status when authentication_method_current.type == OFFLINE" do
      declaration_request = simple_fixture(:declaration_request, "ACTIVE", "OFFLINE")
      person_data = %{"data" => %{"id" => ""}}
      {:ok, %{"data" => data}} = create_declaration_with_termination_logic({:ok, person_data, declaration_request}, [])
      assert "pending_verification" == data["status"]
    end

    test "returns empty status when authentication_method_current.type is unknown" do
      declaration_request = simple_fixture(:declaration_request, "ACTIVE", "SOME_TYPE")
      person_data = %{"data" => %{"id" => ""}}
      {:ok, %{"data" => data}} = create_declaration_with_termination_logic({:ok, person_data, declaration_request}, [])
      assert "" == data["status"]
    end
  end

  describe "update_declaration_request_status/2" do
    test "updates declaration request status to SIGNED and drops unnecessary fields in response" do
      %DeclarationRequest{id: id} = simple_fixture(:declaration_request)
      declaration_response_data = %{"updated_by" => "", "updated_at" => "", "created_by" => "", "another_key" => ""}
      declaration_response = %{"data" => declaration_response_data}
      {:ok, data} = update_declaration_request_status({:ok, declaration_response}, %{"id" => id})
      refute Map.has_key?(data, "updated_by")
      refute Map.has_key?(data, "updated_at")
      refute Map.has_key?(data, "created_by")
      assert Map.has_key?(data, "another_key")
      %DeclarationRequest{status: status} = Repo.get!(DeclarationRequest, id)
      assert "SIGNED" == status
    end
  end
end
