defmodule EHealth.Web.DeclarationsControllerTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import EHealth.MockServer, only: [get_client_admin: 0, get_client_mis: 0, get_client_nil: 0]

  @declaration_id "156b4182-f9ce-4eda-b6af-43d2de8601z2"

  describe "list declarations" do
    test "with x-consumer-metadata that contains MSP client_id with empty client_type_name", %{conn: conn} do
      conn = put_client_id_header(conn, get_client_nil())
      conn = get conn, declarations_path(conn, :index, [edrpou: "37367387"])
      json_response(conn, 401)
    end

    test "by person_id", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375222")
      conn = get conn, declarations_path(conn, :index, [person_id: "7cc91a5d-c02f-41e9-b571-1ea4f2375400"])
      resp = json_response(conn, 200)
      assert 2 == Enum.count(resp["data"])
    end

    test "empty by person_id", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375222")
      conn = get conn, declarations_path(conn, :index, [person_id: Ecto.UUID.generate()])
      assert [] = json_response(conn, 200)["data"]
    end

    test "with x-consumer-metadata that contains MSP client_id with empty declarations list", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375222")
      conn = get conn, declarations_path(conn, :index, [edrpou: "37367387"])
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert [] == resp["data"]
    end

    test "with x-consumer-metadata that contains MSP client_id and invalid legal_entity_id", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375222")
      conn = get conn, declarations_path(conn, :index, [legal_entity_id: "296da7d2-3c5a-4f6a-b8b2-631063737271"])
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert [] == resp["data"]
    end

    test "with x-consumer-metadata that contains MSP client_id", %{conn: conn} do
      division = insert(:prm, :division, id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")
      legal_entity = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      insert(:prm, :employee,
        id: "7488a646-e31f-11e4-aace-600308960662",
        legal_entity: legal_entity,
        division: division
      )
      %{id: legal_entity_id} = legal_entity
      conn = put_client_id_header(conn, legal_entity_id)
      conn = get conn, declarations_path(conn, :index, [legal_entity_id: legal_entity_id])
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      Enum.each(resp["data"], &assert_declaration_expanded_fields(&1))
    end

    test "with x-consumer-metadata that contains MIS client_id", %{conn: conn} do
      legal_id = "296da7d2-3c5a-4f6a-b8b2-631063737271"
      conn = put_client_id_header(conn, legal_id)
      conn = get conn, declarations_path(conn, :index, [legal_entity_id: legal_id])
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 2 == length(resp["data"])
    end

    test "with x-consumer-metadata that contains NHS client_id", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: get_client_admin())
      division = insert(:prm, :division, id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")
      insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      insert(:prm, :employee,
        id: "7488a646-e31f-11e4-aace-600308960662",
        legal_entity: legal_entity,
        division: division
      )
      %{id: legal_entity_id} = legal_entity
      conn = put_client_id_header(conn, legal_entity_id)
      conn = get conn, declarations_path(conn, :index, [legal_entity_id: legal_entity_id])
      resp = json_response(conn, 200)

      assert Map.has_key?(resp, "data")
      assert Map.has_key?(resp, "paging")
      assert is_list(resp["data"])
      assert 3 == length(resp["data"])
      Enum.each(resp["data"], &assert_declaration_expanded_fields(&1))
    end
  end

  describe "declaration by id" do
    test "with x-consumer-metadata that contains MSP client_id with empty client_type_name", %{conn: conn} do
      conn = put_client_id_header(conn, get_client_nil())
      conn = get conn, declarations_path(conn, :show, @declaration_id)
      json_response(conn, 401)
    end

    test "with x-consumer-metadata that contains MSP client_id with undefined declaration id", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375222")
      conn = get conn, declarations_path(conn, :show, "226b4182-f9ce-4eda-b6af-43d2de8600a0")
      json_response(conn, 404)
    end

    test "with x-consumer-metadata that contains MSP client_id with invalid legal_entity_id", %{conn: conn} do
      conn = put_client_id_header(conn, "7cc91a5d-c02f-41e9-b571-1ea4f2375000")
      conn = get conn, declarations_path(conn, :show, @declaration_id)
      json_response(conn, 403)
    end

    test "with x-consumer-metadata that contains MSP client_id", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, id: "7cc91a5d-c02f-41e9-b571-1ea4f2375552")
      division = insert(:prm, :division, id: "b075f148-7f93-4fc2-b2ec-2d81b19a9b7b")
      insert(:prm, :employee,
        id: "7488a646-e31f-11e4-aace-600308960662",
        legal_entity: legal_entity,
        division: division
      )
      conn = put_client_id_header(conn, legal_entity.id)
      conn = get conn, declarations_path(conn, :show, @declaration_id)
      data = json_response(conn, 200)["data"]
      assert_declaration_expanded_fields(data)
    end

    test "with x-consumer-metadata that contains MIS client_id", %{conn: conn} do
      conn = put_client_id_header(conn, get_client_mis())
      conn = get conn, declarations_path(conn, :show, @declaration_id)
      data = json_response(conn, 200)["data"]
      assert is_map(data)
      assert @declaration_id == data["id"]
    end

    test "with x-consumer-metadata that contains NHS client_id", %{conn: conn} do
      conn = put_client_id_header(conn, get_client_admin())
      conn = get conn, declarations_path(conn, :show, @declaration_id)
      data = json_response(conn, 200)["data"]
      assert is_map(data)
      assert @declaration_id == data["id"]
    end
  end

  def assert_declaration_expanded_fields(declaration) do
    fields = ~W(person employee division legal_entity)
    assert is_map(declaration)
    assert declaration["declaration_request_id"]
    Enum.each(fields, fn (field) ->
      assert Map.has_key?(declaration, field), "Expected field #{field} not present"
      assert is_map(declaration[field]), "Expected that field #{field} is map"
      assert Enum.any?([:id, "id"], &(Map.has_key?(declaration[field], &1))), "Expected field #{field}.id not present"
      refute Map.has_key?(declaration, field <> "_id"), "Field #{field}_id should be not present"
    end)
  end

  describe "approve/2 - Happy case" do
    defmodule ApproveOPSMicroservice do
      use MicroservicesHelper

      Plug.Router.get "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => true,
          "status" => "pending_verification"
        }

        send_resp(conn, 200, Poison.encode!(%{data: declaration}))
      end

      Plug.Router.patch "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        %{
          "declaration" => %{
            "status" => "active",
            "updated_by" => "80ff0b87-25a1-4819-bf33-37db90977437"
          }
        } = conn.params

        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => true,
          "status" => "approved"
        }

        send_resp(conn, 200, Poison.encode!(%{meta: %{code: 200}, data: declaration}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(ApproveOPSMicroservice)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, %{port: port, conn: conn}}
    end

    test "it transitions declaration to approved status" do
      user_id = "80ff0b87-25a1-4819-bf33-37db90977437"
      client_id = "d8ea20e3-5949-46e6-88ef-62c708e57ad7"
      declaration_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      response =
        build_conn()
        |> put_req_header("x-consumer-id", user_id)
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/#{declaration_id}/actions/approve")

      response = json_response(response, 200)

      assert "approved" = response["data"]["status"]
    end
  end

  describe "approve/2 - not owner of declaration" do
    defmodule ApproveNotOwnerOfDeclaration do
      use MicroservicesHelper

      Plug.Router.get "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => true,
          "status" => "pending_verification"
        }

        send_resp(conn, 200, Poison.encode!(%{data: declaration}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(ApproveNotOwnerOfDeclaration)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, %{port: port, conn: conn}}
    end

    test "a 403 error is returned" do
      client_id = Ecto.UUID.generate()
      declaration_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      response =
        build_conn()
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/#{declaration_id}/actions/approve")

      assert json_response(response, 403)
    end
  end

  describe "approve/2 - declaration was inactive" do
    defmodule ApproveDeclarationIsInactive do
      use MicroservicesHelper

      Plug.Router.get "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => false,
          "status" => "pending_verification"
        }

        send_resp(conn, 200, Poison.encode!(%{data: declaration}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(ApproveDeclarationIsInactive)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, %{port: port, conn: conn}}
    end

    test "a 404 error is returned (as if declaration never existed)" do
      client_id = "d8ea20e3-5949-46e6-88ef-62c708e57ad7"
      declaration_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      response =
        build_conn()
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/#{declaration_id}/actions/approve")

      assert json_response(response, 404)
    end
  end

  describe "approve/2 - could not transition status" do
    defmodule ApproveCannotTransitionStatus do
      use MicroservicesHelper

      Plug.Router.get "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => true,
          "status" => "approved"
        }

        send_resp(conn, 200, Poison.encode!(%{data: declaration}))
      end

      Plug.Router.patch "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        %{
          "declaration" => %{
            "status" => "active",
            "updated_by" => "80ff0b87-25a1-4819-bf33-37db90977437"
          }
        } = conn.params

        error_resp = %{
          meta: %{
            code: 422
          },
          error: %{
            message: "some_eview_message"
          }
        }

        send_resp(conn, 422, Poison.encode!(error_resp))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(ApproveCannotTransitionStatus)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, %{port: port, conn: conn}}
    end

    test "a 409 error is returned" do
      user_id = "80ff0b87-25a1-4819-bf33-37db90977437"
      client_id = "d8ea20e3-5949-46e6-88ef-62c708e57ad7"
      declaration_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      response =
        build_conn()
        |> put_req_header("x-consumer-id", user_id)
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/#{declaration_id}/actions/approve")

      assert json_response(response, 409)
    end
  end

  describe "reject/2 - Happy case" do
    defmodule OPSMicroservice do
      use MicroservicesHelper

      Plug.Router.get "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => true,
          "status" => "pending_verification"
        }

        send_resp(conn, 200, Poison.encode!(%{data: declaration}))
      end

      Plug.Router.patch "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        %{
          "declaration" => %{
            "status" => "rejected",
            "updated_by" => "80ff0b87-25a1-4819-bf33-37db90977437"
          }
        } = conn.params

        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => true,
          "status" => "rejected"
        }

        send_resp(conn, 200, Poison.encode!(%{meta: %{code: 200}, data: declaration}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(OPSMicroservice)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, %{port: port, conn: conn}}
    end

    test "it transitions declaration to rejected status" do
      user_id = "80ff0b87-25a1-4819-bf33-37db90977437"
      client_id = "d8ea20e3-5949-46e6-88ef-62c708e57ad7"
      declaration_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      response =
        build_conn()
        |> put_req_header("x-consumer-id", user_id)
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/#{declaration_id}/actions/reject")

      response = json_response(response, 200)

      assert "rejected" = response["data"]["status"]
    end
  end

  describe "reject/2 - not owner of declaration" do
    defmodule NotOwnerOfDeclaration do
      use MicroservicesHelper

      Plug.Router.get "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => true,
          "status" => "pending_verification"
        }

        send_resp(conn, 200, Poison.encode!(%{data: declaration}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(NotOwnerOfDeclaration)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, %{port: port, conn: conn}}
    end

    test "a 403 error is returned" do
      client_id = Ecto.UUID.generate()
      declaration_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      response =
        build_conn()
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/#{declaration_id}/actions/reject")

      assert json_response(response, 403)
    end
  end

  describe "reject/2 - declaration was inactive" do
    defmodule DeclarationIsInactive do
      use MicroservicesHelper

      Plug.Router.get "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => false,
          "status" => "pending_verification"
        }

        send_resp(conn, 200, Poison.encode!(%{data: declaration}))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(DeclarationIsInactive)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, %{port: port, conn: conn}}
    end

    test "a 404 error is returned (as if declaration never existed)" do
      client_id = "d8ea20e3-5949-46e6-88ef-62c708e57ad7"
      declaration_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      response =
        build_conn()
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/#{declaration_id}/actions/reject")

      assert json_response(response, 404)
    end
  end

  describe "reject/2 - could not transition status" do
    defmodule CannotTransitionStatus do
      use MicroservicesHelper

      Plug.Router.get "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        declaration = %{
          "id" => "ce377dea-d8c4-4dd8-9328-de24b1ee3879",
          "legal_entity_id" => "d8ea20e3-5949-46e6-88ef-62c708e57ad7",
          "is_active" => true,
          "status" => "closed"
        }

        send_resp(conn, 200, Poison.encode!(%{data: declaration}))
      end

      Plug.Router.patch "/declarations/ce377dea-d8c4-4dd8-9328-de24b1ee3879" do
        %{
          "declaration" => %{
            "status" => "rejected",
            "updated_by" => "80ff0b87-25a1-4819-bf33-37db90977437"
          }
        } = conn.params

        error_resp = %{
          meta: %{
            code: 422
          },
          error: %{
            message: "some_eview_message"
          }
        }

        send_resp(conn, 422, Poison.encode!(error_resp))
      end
    end

    setup %{conn: conn} do
      {:ok, port, ref} = start_microservices(CannotTransitionStatus)

      System.put_env("OPS_ENDPOINT", "http://localhost:#{port}")
      on_exit fn ->
        System.put_env("OPS_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

      {:ok, %{port: port, conn: conn}}
    end

    test "a 409 error is returned" do
      user_id = "80ff0b87-25a1-4819-bf33-37db90977437"
      client_id = "d8ea20e3-5949-46e6-88ef-62c708e57ad7"
      declaration_id = "ce377dea-d8c4-4dd8-9328-de24b1ee3879"

      response =
        build_conn()
        |> put_req_header("x-consumer-id", user_id)
        |> put_client_id_header(client_id)
        |> patch("/api/declarations/#{declaration_id}/actions/reject")

      assert json_response(response, 409)
    end
  end
end
