defmodule EHealth.Integraiton.DeclarationRequest.API.SignTest do
  @moduledoc false

  alias EHealth.Repo
  use EHealth.Web.ConnCase
  import EHealth.DeclarationRequest.API.Sign
  alias EHealth.DeclarationRequest

  defp fixture(status \\ "ACTIVE", authentication_method_current_type \\ "OTP") do
    data =
      "test/data/sign_declaration_request.json"
      |> File.read!()
      |> Poison.decode!

    Repo.insert!(%DeclarationRequest{
      data: data,
      status: status,
      inserted_by: Ecto.UUID.generate(),
      updated_by: Ecto.UUID.generate(),
      authentication_method_current: %{"type" => authentication_method_current_type},
      printout_content: ""
    })
  end

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
      %DeclarationRequest{id: id} = fixture()
      result = check_status({:ok, "somedata"}, %{"id" => id})
      expected_result = {:error, [{%{description: "incorrect status", params: [], rule: :invalid}, "$.status"}]}
      assert expected_result == result
    end

    test "returns expected result when status is APPROVED" do
      declaration_request = %DeclarationRequest{id: id} = fixture("APPROVED")
      assert {:ok, "somedata", declaration_request} == check_status({:ok, "somedata"}, %{"id" => id})
    end
  end

  describe "compare_with_db/1" do
    test "returns error when data does not match" do
      result = compare_with_db({:ok, %{"data" => %{"content" => "somedata"}}, %{data: "some_data"}})
      expected_result = {:error, [{%{description: "Signed content does not match the previously created content",
        params: [], rule: :invalid}, "$.content"}]}
      assert expected_result == result
    end

    test "returns expected result when data matches" do
      result = compare_with_db({:ok, %{"data" => %{"content" => "somedata"}}, %{data: "somedata"}})
      expected_result = {:ok, %{data: "somedata"}}
      assert expected_result == result
    end
  end

  describe "create_or_update_person/2" do
    defmodule MPIMock do
      use MicroservicesHelper

      Plug.Router.post "/persons" do
        send_resp(conn, 200, Poison.encode!(%{data: "somedata"}))
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
      declaration_request = fixture()
      expected_result = {:ok, %{"data" => "somedata"}, declaration_request}
      assert ^expected_result = create_or_update_person({:ok, declaration_request}, [])
    end
  end

  describe "create_declaration_with_termination_logic/2" do
    defmodule OPSMock do
      use MicroservicesHelper

      Plug.Router.post "/declarations/with_termination" do
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
      %DeclarationRequest{data: declaration_request_data} = declaration_request = fixture()
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
      assert "active" == data["status"]
      assert data["is_active"]
    end

    test "returns pending_validation status when authentication_method_current.type == OFFLINE" do
      declaration_request = fixture("ACTIVE", "OFFLINE")
      person_data = %{"data" => %{"id" => ""}}
      {:ok, %{"data" => data}} = create_declaration_with_termination_logic({:ok, person_data, declaration_request}, [])
      assert "pending_verification" == data["status"]
    end

    test "returns empty status when authentication_method_current.type is unknown" do
      declaration_request = fixture("ACTIVE", "SOME_TYPE")
      person_data = %{"data" => %{"id" => ""}}
      {:ok, %{"data" => data}} = create_declaration_with_termination_logic({:ok, person_data, declaration_request}, [])
      assert "" == data["status"]
    end
  end

  describe "update_declaration_request_status/2" do
    test "updates declaration request status to SIGNED and drops unnecessary fields in response" do
      %DeclarationRequest{id: id} = fixture()
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
