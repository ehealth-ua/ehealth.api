defmodule GraphQL.DeclarationResolverTest do
  @moduledoc false

  use GraphQL.ConnCase, async: false

  import Core.Expectations.Mithril, only: [nhs: 1]
  import Core.Factories
  import Core.Utils.TypesConverter, only: [strings_to_keys: 1]
  import Mox

  alias Ecto.UUID
  alias Absinthe.Relay.Node

  @declaration_fields """
    id
    databaseId
    declarationNumber
    startDate
    endDate
    signedAt
    status
    scope
    reason
    reasonDescription
    legalEntity{id kveds}
    division{id email}
    employee{id start_date employee_type}
    person{
      id
      databaseId
      unzr
      addresses {
        settlementType
        zip
      }
    }
  """

  @declaration_pending_query """
    query DeclarationsPendingQuery($filter: PendingDeclarationFilter, $orderBy: DeclarationOrderBy){
      pendingDeclarations(first: 10, filter: $filter, orderBy: $orderBy){
        nodes{
          #{@declaration_fields}
          declarationAttachedDocuments {
            type
            url
          }
        }
      }
    }
  """

  @declaration_by_id_query """
    query GetDeclarationQuery($id: ID!) {
      declaration(id: $id) {
        #{@declaration_fields}
      }
    }
  """

  @declaration_by_number_query """
    query DeclarationByNumberQuery($declarationNumber: String!) {
      declarationByNumber(declarationNumber: $declarationNumber) {
        #{@declaration_fields}
        declarationAttachedDocuments {
          type
          url
        }
      }
    }
  """

  @approve_declaration_query """
    mutation ApproveDeclarationMutation($input: ApproveDeclarationInput!) {
      approveDeclaration(input: $input) {
        declaration {
          id
          databaseId
          status
        }
      }
    }
  """

  @reject_declaration_query """
    mutation RejectDeclarationMutation($input: RejectDeclarationInput!) {
      rejectDeclaration(input: $input) {
        declaration {
          id
          databaseId
          status
        }
      }
    }
  """

  @terminate_declaration_query """
    mutation TerminateDeclarationMutation($input: TerminateDeclarationInput!) {
      terminateDeclaration(input: $input) {
        declaration {
          id
          databaseId
          reasonDescription
          legalEntity {
            id
            databaseId
          }
        }
      }
    }
  """

  @status_active "active"
  @status_rejected "rejected"
  @status_pending "pending_verification"
  @status_terminated "terminated"

  setup :verify_on_exit!
  setup :set_mox_global

  setup %{conn: conn} do
    scopes = "declaration:read declaration_documents:read declaration:approve declaration:reject declaration:terminate"
    {:ok, %{conn: put_scope(conn, scopes)}}
  end

  describe "pending declarations list" do
    test "success with search params", %{conn: conn} do
      persons = build_list(8, :person)
      documents = [%{"url" => "http://link-to-documents.web", "type" => "person.no_tax_id"}]

      declarations =
        [
          persons,
          insert_list(8, :prm, :division),
          insert_list(8, :prm, :employee),
          insert_list(8, :prm, :legal_entity),
          insert_list(8, :il, :declaration_request, documents: documents)
        ]
        |> Enum.zip()
        |> Enum.map(fn {person, division, employee, legal_entity, declaration_request} ->
          build(:declaration,
            status: @status_pending,
            person_id: person.id,
            division_id: division.id,
            employee_id: employee.id,
            legal_entity_id: legal_entity.id,
            declaration_request_id: declaration_request.id
          )
        end)

      expect(RPCWorkerMock, :run, fn _, _, :search_declarations, _ -> {:ok, declarations} end)
      expect(RPCWorkerMock, :run, fn _, _, :ql_search, _ -> {:ok, persons} end)

      expect(MediaStorageMock, :create_signed_url, 8, fn _, _, _, _ ->
        {:ok, %{secret_url: "http://example.com/signed_url_test"}}
      end)

      variables = %{
        filter: %{reason: "NO_TAX_ID"},
        orderBy: "STATUS_ASC"
      }

      resp_body =
        conn
        |> post_query(@declaration_pending_query, variables)
        |> json_response(200)

      resp_entities = [resp_entity | _] = get_in(resp_body, ~w(data pendingDeclarations nodes))

      refute resp_body["errors"]
      assert 8 == length(resp_entities)

      query_fields =
        ~w(id databaseId declarationNumber startDate endDate signedAt status scope reason reasonDescription legalEntity division employee person declarationAttachedDocuments)

      assert Enum.all?(query_fields, &Map.has_key?(resp_entity, &1))
      assert hd(resp_entity["person"]["addresses"])["zip"]
      assert [%{"url" => _, "type" => _}] = resp_entity["declarationAttachedDocuments"]
    end

    test "success: empty results", %{conn: conn} do
      expect(RPCWorkerMock, :run, fn _, _, :search_declarations, _ -> {:ok, []} end)
      variables = %{order_by: "STATUS_ASC"}

      resp_body =
        conn
        |> post_query(@declaration_pending_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data pendingDeclarations nodes))

      refute resp_body["errors"]
      assert [] == resp_entities
    end
  end

  describe "get by id and number" do
    setup %{conn: conn} do
      documents = [%{"url" => "http://link-to-documents.web", "type" => "person.no_tax_id"}]
      declaration_request = insert(:il, :declaration_request, documents: documents)
      division = insert(:prm, :division)
      employee = insert(:prm, :employee)
      legal_entity = insert(:prm, :legal_entity)
      person = build(:person)

      declaration =
        build(:declaration,
          division_id: division.id,
          employee_id: employee.id,
          legal_entity_id: legal_entity.id,
          person_id: person.id,
          declaration_request_id: declaration_request.id
        )

      %{conn: conn, declaration: declaration, person: person}
    end

    test "success by id", %{conn: conn, declaration: declaration, person: person} do
      expect(RPCWorkerMock, :run, fn _, _, :get_declaration, _ -> {:ok, declaration} end)
      expect(RPCWorkerMock, :run, fn _, _, :ql_search, _ -> {:ok, [person]} end)

      id = Node.to_global_id("Declaration", declaration.id)
      variables = %{id: id}

      resp_body =
        conn
        |> post_query(@declaration_by_id_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data declaration))

      refute resp_body["errors"]
      assert id == resp_entity["id"]
      assert declaration.id == resp_entity["databaseId"]
    end

    test "success by declaration number", %{conn: conn, declaration: declaration, person: person} do
      %{id: declaration_id, declaration_number: declaration_number} = declaration

      expect(RPCWorkerMock, :run, fn _, _, :get_declaration, _ -> {:ok, declaration} end)
      expect(RPCWorkerMock, :run, fn _, _, :ql_search, _ -> {:ok, [person]} end)

      expect(MediaStorageMock, :create_signed_url, fn _, _, _, _ ->
        {:ok, %{secret_url: "http://example.com/signed_url_test"}}
      end)

      id = Node.to_global_id("Declaration", declaration_id)
      variables = %{declarationNumber: declaration_number}

      resp_body =
        conn
        |> post_query(@declaration_by_number_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data declarationByNumber))

      refute resp_body["errors"]
      assert id == resp_entity["id"]
      assert declaration_id == resp_entity["databaseId"]
      assert declaration_number == resp_entity["declarationNumber"]
      assert [%{"url" => _, "type" => _}] = resp_entity["declarationAttachedDocuments"]
    end

    test "not found by id", %{conn: conn} do
      expect(RPCWorkerMock, :run, fn _, _, :get_declaration, _ -> nil end)
      variables = %{id: Node.to_global_id("Declaration", UUID.generate())}

      resp_body =
        conn
        |> post_query(@declaration_by_id_query, variables)
        |> json_response(200)

      %{"errors" => [error]} = resp_body

      refute get_in(resp_body, ~w(data declaration))
      assert "NOT_FOUND" == error["extensions"]["code"]
    end

    test "not found by declaration number", %{conn: conn} do
      expect(RPCWorkerMock, :run, fn _, _, :get_declaration, _ -> nil end)
      variables = %{declarationNumber: Node.to_global_id("Declaration", UUID.generate())}

      resp_body =
        conn
        |> post_query(@declaration_by_number_query, variables)
        |> json_response(200)

      %{"errors" => [error]} = resp_body

      refute get_in(resp_body, ~w(data declarationByNumber))
      assert "NOT_FOUND" == error["extensions"]["code"]
    end
  end

  describe "approve declaration" do
    test "success", %{conn: conn} do
      consumer_id = UUID.generate()
      declaration = build(:declaration, status: @status_pending)

      nhs(2)

      expect(RPCWorkerMock, :run, fn _, _, :get_declaration, [[id: id]] ->
        assert id == declaration.id
        {:ok, declaration}
      end)

      expect(RPCWorkerMock, :run, fn _, _, :update_declaration, [id, patch] ->
        assert id == declaration.id
        assert @status_active == patch["status"]
        assert consumer_id == patch["updated_by"]

        {:ok, Map.merge(declaration, strings_to_keys(patch))}
      end)

      variables = %{input: %{id: Node.to_global_id("Declaration", declaration.id)}}

      resp_body =
        conn
        |> put_client_id()
        |> put_consumer_id(consumer_id)
        |> post_query(@approve_declaration_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data approveDeclaration declaration))

      refute resp_body["errors"]
      assert declaration.id == resp_entity["databaseId"]
      assert "ACTIVE" == resp_entity["status"]
    end
  end

  describe "reject declaration" do
    test "success", %{conn: conn} do
      consumer_id = UUID.generate()
      declaration = build(:declaration, status: @status_pending)

      nhs(2)

      expect(RPCWorkerMock, :run, fn _, _, :get_declaration, [[id: id]] ->
        assert id == declaration.id
        {:ok, declaration}
      end)

      expect(RPCWorkerMock, :run, fn _, _, :update_declaration, [id, patch] ->
        assert id == declaration.id
        assert @status_rejected == patch["status"]
        assert consumer_id == patch["updated_by"]

        {:ok, Map.merge(declaration, strings_to_keys(patch))}
      end)

      variables = %{input: %{id: Node.to_global_id("Declaration", declaration.id)}}

      resp_body =
        conn
        |> put_client_id()
        |> put_consumer_id(consumer_id)
        |> post_query(@reject_declaration_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data rejectDeclaration declaration))

      refute resp_body["errors"]
      assert declaration.id == resp_entity["databaseId"]
      assert "REJECTED" == resp_entity["status"]
    end
  end

  describe "terminate declaration" do
    test "success", %{conn: conn} do
      database_id = UUID.generate()
      person_id = UUID.generate()
      reason_description = "some reason"
      consumer_id = UUID.generate()

      %{id: client_id} = insert(:prm, :legal_entity)
      person = build(:person, id: person_id)
      declaration = build(:declaration, id: database_id, person_id: person_id, legal_entity_id: client_id)

      nhs(2)

      expect(MithrilMock, :get_user_by_id, fn id, _ ->
        assert id == consumer_id

        {:ok,
         %{
           "data" => %{
             "id" => id,
             "email" => "mis_bot_1493831618@user.com",
             "type" => "user",
             "person_id" => person_id
           }
         }}
      end)

      expect(RPCWorkerMock, :run, fn _, _, :get_declaration, _ -> {:ok, declaration} end)
      expect(RPCWorkerMock, :run, fn _, _, :get_person_by_id, _ -> {:ok, person} end)

      expect(RPCWorkerMock, :run, fn _, _, :terminate_declaration, [id, _] ->
        assert id == declaration.id
        {:ok, %{declaration | status: @status_terminated}}
      end)

      variables = %{input: %{id: Node.to_global_id("Declaration", database_id), reason_description: reason_description}}

      resp_body =
        conn
        |> put_client_id(client_id)
        |> put_consumer_id(consumer_id)
        |> post_query(@terminate_declaration_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data terminateDeclaration declaration))

      refute resp_body["errors"]
      assert database_id == resp_entity["databaseId"]
      assert client_id == resp_entity["legalEntity"]["databaseId"]
    end
  end
end
