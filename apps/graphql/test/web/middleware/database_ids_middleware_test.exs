defmodule GraphQLWeb.DatabaseIDsMiddlewareTest do
  use GraphQLWeb.ConnCase, async: true

  import Core.Factories

  alias Absinthe.Relay.Node

  setup context do
    conn = put_scope(context.conn, "legal_entity:read")

    {:ok, %{conn: conn}}
  end

  describe "database IDs middleware" do
    test "success on entity lists", %{conn: conn} do
      legal_entities = for _ <- 0..1, do: insert(:prm, :legal_entity)

      query = """
        {
          legalEntities(first: 2) {
            nodes {
              databaseId
            }
          }
        }
      """

      resp_body =
        conn
        |> post_query(query)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data legalEntities nodes))

      assert nil == resp_body["errors"]

      Enum.each(legal_entities, fn legal_entitity ->
        assert Enum.any?(resp_entities, &(legal_entitity.id == &1["databaseId"]))
      end)
    end

    test "success on single entities", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)

      id = Node.to_global_id("LegalEntity", legal_entity.id)

      query = """
        query GetLegalEntityQuery($id: ID!) {
          legalEntity(id: $id) {
            databaseId
          }
        }
      """

      variables = %{id: id}

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data legalEntity))

      assert nil == resp_body["errors"]
      assert legal_entity.id == resp_entity["databaseId"]
    end
  end
end
