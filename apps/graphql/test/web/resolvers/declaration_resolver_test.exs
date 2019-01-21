defmodule GraphQLWeb.DeclarationResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: false

  import Core.Factories
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

    declarationAttachedDocuments{
      type
      url
    }
  """

  @declaration_pending_query """
    query DeclarationsPendingQuery($filter: PendingDeclarationFilter, $orderBy: DeclarationOrderBy){
      pendingDeclarations(first: 10, filter: $filter, orderBy: $orderBy){
        nodes{
          #{@declaration_fields}
        }
      }
    }
  """

  @declaration_by_id_query """
    query declarationQuery($id: ID!) {
      declaration(id: $id) {
        #{@declaration_fields}
      }
    }
  """

  @declaration_by_number_query """
    query DeclarationByNumberQuery($declarationNumber: String!) {
      declarationByNumber(declarationNumber: $declarationNumber) {
        #{@declaration_fields}
      }
    }
  """

  @status_pending "pending_verification"

  setup :verify_on_exit!
  setup :set_mox_global

  setup context do
    conn = put_scope(context.conn, "declaration:read")

    {:ok, %{conn: conn}}
  end

  describe "pending declarations list" do
    test "success with search params", %{conn: conn} do
      persons = build_list(8, :mpi_person)
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
          build(:ops_declaration,
            status: @status_pending,
            person_id: person.id,
            division_id: division.id,
            employee_id: employee.id,
            legal_entity_id: legal_entity.id,
            declaration_request_id: declaration_request.id
          )
        end)

      expect(RPCWorkerMock, :run, fn _, _, :search_declarations, _ -> {:ok, declarations} end)
      expect(RPCWorkerMock, :run, fn _, _, :search_persons, _ -> {:ok, persons} end)

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

      assert hd(resp_entity["declarationAttachedDocuments"])["url"]
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
      division = insert(:prm, :division)
      employee = insert(:prm, :employee)
      legal_entity = insert(:prm, :legal_entity)
      person = build(:mpi_person)

      declaration =
        build(:ops_declaration,
          division_id: division.id,
          employee_id: employee.id,
          legal_entity_id: legal_entity.id,
          person_id: person.id
        )

      %{conn: conn, declaration: declaration, person: person}
    end

    test "success by id", %{conn: conn, declaration: declaration, person: person} do
      expect(RPCWorkerMock, :run, fn _, _, :get_declaration, _ -> declaration end)
      expect(RPCWorkerMock, :run, fn _, _, :search_persons, _ -> {:ok, [person]} end)

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

      expect(RPCWorkerMock, :run, fn _, _, :get_declaration, _ -> declaration end)
      expect(RPCWorkerMock, :run, fn _, _, :search_persons, _ -> {:ok, [person]} end)

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
end
