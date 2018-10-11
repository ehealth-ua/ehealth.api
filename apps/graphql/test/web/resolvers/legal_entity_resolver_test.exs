defmodule GraphQLWeb.LegalEntityResolverTest do
  use GraphQLWeb.ConnCase, async: true

  import Core.Factories

  alias Absinthe.Relay.Node

  setup %{conn: conn} do
    conn = put_scope(conn, "legal_entity:read legal_entity:write")

    {:ok, %{conn: conn}}
  end

  describe "list" do
    test "success without params", %{conn: conn} do
      insert(:prm, :legal_entity)
      insert(:prm, :legal_entity)

      query = """
        {
          legalEntities(first: 10) {
            nodes {
              id
              publicName
            }
          }
        }
      """

      legal_entities =
        conn
        |> post_query(query)
        |> json_response(200)
        |> get_in(~w(data legalEntities nodes))

      assert 2 == length(legal_entities)

      Enum.each(legal_entities, fn legal_entity ->
        assert Map.has_key?(legal_entity, "id")
        assert Map.has_key?(legal_entity, "publicName")
      end)
    end

    test "success with filter", %{conn: conn} do
      for edrpou <- ["1234567890", "0987654321"], do: insert(:prm, :legal_entity, edrpou: edrpou)

      query = """
        query ListLegalEntitiesQuery($first: Int!, $filter: LegalEntityFilter!) {
          legalEntities(first: $first, filter: $filter) {
            nodes {
              id
              edrpou
            }
          }
        }
      """

      variables = %{first: 10, filter: %{edrpou: "1234567890"}}

      legal_entities =
        conn
        |> post_query(query, variables)
        |> json_response(200)
        |> get_in(~w(data legalEntities nodes))

      assert 1 == length(legal_entities)
      assert "1234567890" == hd(legal_entities)["edrpou"]
    end

    test "success with ordering", %{conn: conn} do
      for edrpou <- ["1234567890", "0987654321"], do: insert(:prm, :legal_entity, edrpou: edrpou)

      query = """
        query ListLegalEntitiesQuery($first: Int!, $order_by: LegalEntityFilter!) {
          legalEntities(first: $first, orderBy: $order_by) {
            nodes {
              id
              edrpou
            }
          }
        }
      """

      variables = %{first: 10, order_by: "EDRPOU_ASC"}

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data legalEntities nodes))

      assert nil == resp_body["errors"]
      assert "0987654321" == hd(resp_entities)["edrpou"]
    end

    test "cursor pagination", %{conn: conn} do
      insert(:prm, :legal_entity)
      insert(:prm, :legal_entity)
      insert(:prm, :legal_entity)

      query = """
        query ListLegalEntitiesQuery($first: Int!) {
          legalEntities(first: $first) {
            pageInfo {
              startCursor
              endCursor
              hasPreviousPage
              hasNextPage
            }
            nodes {
              id
              publicName
              addresses {
                type
                country
              }
            }
          }
        }
      """

      variables = %{first: 2}

      data =
        conn
        |> post_query(query, variables)
        |> json_response(200)
        |> get_in(~w(data legalEntities))

      assert 2 == length(data["nodes"])
      assert data["pageInfo"]["hasNextPage"]
      refute data["pageInfo"]["hasPreviousPage"]

      query = """
        query ListLegalEntitiesQuery($first: Int!, $after: String!) {
          legalEntities(first: $first, after: $after) {
            pageInfo {
              hasPreviousPage
              hasNextPage
            }
            nodes {
              id
              publicName
            }
          }
        }
      """

      variables = %{first: 2, after: data["pageInfo"]["endCursor"]}

      data =
        conn
        |> post_query(query, variables)
        |> json_response(200)
        |> get_in(~w(data legalEntities))

      assert 1 == length(data["nodes"])
      refute data["pageInfo"]["hasNextPage"]
      assert data["pageInfo"]["hasPreviousPage"]
    end
  end

  describe "get by id" do
    test "success", %{conn: conn} do
      insert(:prm, :legal_entity)
      phone = %{"type" => "MOBILE", "number" => "+380201112233"}
      legal_entity = insert(:prm, :legal_entity, phones: [phone])

      id = Node.to_global_id("LegalEntity", legal_entity.id)

      query = """
        query GetLegalEntityQuery($id: ID) {
          legalEntity(id: $id) {
            id
            publicName
            nhsVerified
            phones {
              type
              number
            }
            addresses {
              type
              country
            }
            archive {
              date
              place
            }
            medicalServiceProvider {
              licenses {
                licenseNumber
                whatLicensed
              }
              accreditation {
                category
              }
            }
          }
        }
      """

      variables = %{id: id}

      resp =
        conn
        |> post_query(query, variables)
        |> json_response(200)
        |> get_in(~w(data legalEntity))

      assert legal_entity.public_name == resp["publicName"]
      assert legal_entity.phones == resp["phones"]
      assert legal_entity.archive == resp["archive"]
      assert Map.has_key?(resp["medicalServiceProvider"], "licenses")
      assert "some" == get_in(resp, ~w(medicalServiceProvider accreditation category))
    end
  end
end
