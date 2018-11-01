defmodule GraphQLWeb.LegalEntityResolverTest do
  use GraphQLWeb.ConnCase, async: true

  import Core.Factories

  alias Absinthe.Relay.Node
  alias Core.Employees.Employee

  @owner Employee.type(:owner)
  @doctor Employee.type(:doctor)

  setup %{conn: conn} do
    conn = put_scope(conn, "legal_entity:read legal_entity:write")

    {:ok, %{conn: conn}}
  end

  describe "list" do
    test "success without params", %{conn: conn} do
      from = insert(:prm, :legal_entity, edrpou: "1234567890")
      from2 = insert(:prm, :legal_entity, edrpou: "2234567890")
      from3 = insert(:prm, :legal_entity, edrpou: "3234567890")
      to = insert(:prm, :legal_entity)
      insert(:prm, :related_legal_entity, merged_from: from, merged_to: to)
      insert(:prm, :related_legal_entity, merged_from: from2, merged_to: to)
      insert(:prm, :related_legal_entity, merged_from: from3, merged_to: to)

      query = """
        {
          legalEntities(first: 10) {
            pageInfo {
              startCursor
              endCursor
              hasPreviousPage
              hasNextPage
            }
            nodes {
              id
              databaseId
              publicName
              mergedFromLegalEntities(first: 2, filter: {isActive: true}){
                pageInfo {
                  startCursor
                  endCursor
                  hasPreviousPage
                  hasNextPage
                }
                nodes {
                  databaseId
                  reason
                  isActive
                  mergedToLegalEntity {
                    databaseId
                    publicName
                  }
                  mergedFromLegalEntity {
                    databaseId
                    publicName
                  }
                }
              }
              mergedToLegalEntity {
                reason
                isActive
                mergedToLegalEntity {
                  databaseId
                  publicName
                }
              }
            }
          }
        }
      """

      legal_entities =
        conn
        |> post_query(query)
        |> json_response(200)
        |> get_in(~w(data legalEntities nodes))

      assert 4 == length(legal_entities)

      Enum.each(legal_entities, fn legal_entity ->
        Enum.each(~w(id publicName mergedFromLegalEntities), fn field ->
          assert Map.has_key?(legal_entity, field)
        end)
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

    test "success with filter by related legal entity edrpou", %{conn: conn} do
      from = insert(:prm, :legal_entity, edrpou: "1234567890")
      from2 = insert(:prm, :legal_entity, edrpou: "2234567890")
      insert(:prm, :legal_entity, edrpou: "3234567890")
      to = insert(:prm, :legal_entity, edrpou: "3234567899")
      insert(:prm, :related_legal_entity, merged_from: from, merged_to: to)
      related_legal_entity = insert(:prm, :related_legal_entity, merged_from: from2, merged_to: to)

      query = """
        {
          legalEntities(first: 10, filter: {edrpou: "3234567899"}) {
            nodes {
              databaseId
              mergedFromLegalEntities(
                first: 5,
                filter: {
                  mergedFromLegalEntity: {
                    edrpou: "2234567890",
                    is_active: true
                  }
                }
              ){
                nodes {
                  databaseId
                }
              }
            }
          }
        }
      """

      legal_entities =
        conn
        |> post_query(query)
        |> json_response(200)
        |> get_in(~w(data legalEntities nodes))

      assert [legal_entity] = legal_entities

      assert to.id == legal_entity["databaseId"]
      assert [%{"databaseId" => related_legal_entity.id}] == legal_entity["mergedFromLegalEntities"]["nodes"]
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

    test "first param not set", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)

      query = """
      query ListLegalEntitiesQuery {
          legalEntities(first: 1) {
            nodes {
              databaseId
              divisions{
                nodes {
                  databaseId
                }
              }
            }
          }
        }
      """

      data =
        conn
        |> post_query(query)
        |> json_response(200)

      assert legal_entity.id == hd(get_in(data, ~w(data legalEntities nodes)))["databaseId"]
      assert Enum.any?(data["errors"], &match?(%{"message" => "You must either supply `:first` or `:last`"}, &1))
    end

    test "filter by area and settlement", %{conn: conn} do
      insert(:prm, :legal_entity)
      address = Map.merge(build(:address), %{"area" => "ЛЬВІВСЬКА", "settlement" => "ЛЬВІВ"})
      legal_entity = insert(:prm, :legal_entity, addresses: [address])

      query = """
        query ListLegalEntitiesQuery($first: Int!, $filter: LegalEntityFilter!) {
          legalEntities(first: $first, filter: $filter) {
            nodes {
              databaseId
            }
          }
        }
      """

      variables = %{first: 1, filter: %{area: "ЛЬВІВСЬКА", settlement: "ЛЬВІВ", edrpou: legal_entity.edrpou}}

      legal_entities =
        conn
        |> post_query(query, variables)
        |> json_response(200)
        |> get_in(~w(data legalEntities nodes))

      refute [] == legal_entities
      assert legal_entity.id == hd(legal_entities)["databaseId"]
    end
  end

  describe "get by id" do
    test "success", %{conn: conn} do
      insert(:prm, :legal_entity)
      phone = %{"type" => "MOBILE", "number" => "+380201112233"}
      legal_entity = insert(:prm, :legal_entity, phones: [phone])
      division = insert(:prm, :division, legal_entity: legal_entity, name: "Захід Сонця")
      insert(:prm, :division, legal_entity: legal_entity)

      inactive_attrs = [division: division, legal_entity_id: legal_entity.id, employee_type: @owner, is_active: false]
      insert(:prm, :employee, inactive_attrs)
      owner = insert(:prm, :employee, division: division, legal_entity_id: legal_entity.id, employee_type: @owner)
      doctor = insert(:prm, :employee, division: division, legal_entity_id: legal_entity.id, employee_type: @doctor)
      insert(:prm, :employee, inactive_attrs)

      insert(:prm, :related_legal_entity, merged_to: legal_entity, is_active: false)
      related_merged_from = insert(:prm, :related_legal_entity, merged_to: legal_entity)
      insert(:prm, :related_legal_entity, merged_to: legal_entity)
      related_merged_to = insert(:prm, :related_legal_entity, merged_from: legal_entity)

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
            medicalServiceProvider{
              licenses {
                license_number
                issued_by
                issued_date
                active_from_date
                order_no
                expiry_date
                what_licensed
              }
              accreditation{
                category
                order_no
                order_date
                issued_date
                expiry_date
              }
            }
            receiverFundsCode
            owner {
              databaseId
              position
              additionalInfo{
                specialities{
                  speciality
                  speciality_officio
                }
              }
              party {
                databaseId
                firstName
              }
              legal_entity {
                databaseId
                publicName
              }
            }
            employees(first: 2, filter: {isActive: true}){
              nodes {
                databaseId
                additionalInfo{
                  specialities{
                    speciality
                    speciality_officio
                  }
                }
                party {
                  databaseId
                  firstName
                }
                legal_entity {
                  databaseId
                  publicName
                }
              }
            }
            divisions(first: 1){
              nodes {
                databaseId
                name
                email
                addresses {
                  area
                  region
                }
              }
            }
            mergedFromLegalEntities(first: 1, filter: {isActive: true}){
              nodes {
                databaseId
                mergedToLegalEntity {
                  databaseId
                  publicName
                }
                mergedFromLegalEntity {
                  databaseId
                  publicName
                }
              }
            }
            mergedToLegalEntity {
              databaseId
              mergedToLegalEntity {
                databaseId
                publicName
              }
            }
          }
        }
      """

      variables = %{id: id, divisionName: "Захід Сонця", employeeType: "DOCTOR"}

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

      # mergedToLegalEntity
      assert related_merged_to.id == resp["mergedToLegalEntity"]["databaseId"]

      # mergedFromLegalEntity
      assert related_merged_from.id == hd(resp["mergedFromLegalEntities"]["nodes"])["databaseId"]

      # owner
      assert owner.id == resp["owner"]["databaseId"]

      # employees
      employees_from_resp = resp["employees"]["nodes"]
      assert 2 = length(employees_from_resp)

      Enum.each(employees_from_resp, fn employee_from_resp ->
        assert employee_from_resp["databaseId"] in [doctor.id, owner.id]
        assert Map.has_key?(employee_from_resp, "additionalInfo")
        assert Map.has_key?(employee_from_resp, "legal_entity")
        assert Map.has_key?(employee_from_resp["additionalInfo"], "specialities")

        assert [
                 %{
                   "speciality" => "PEDIATRICIAN",
                   "speciality_officio" => true
                 }
               ] == employee_from_resp["additionalInfo"]["specialities"]
      end)

      # msp
      msp = legal_entity.medical_service_provider |> Jason.encode!() |> Jason.decode!()
      assert msp["accreditation"] == resp["medicalServiceProvider"]["accreditation"]
      assert msp["licenses"] == resp["medicalServiceProvider"]["licenses"]

      # divisions
      assert 1 == length(resp["divisions"]["nodes"])
      division_from_resp = hd(resp["divisions"]["nodes"])
      assert division.id == division_from_resp["databaseId"]
      assert match?(%{"area" => _, "region" => _}, hd(division_from_resp["addresses"]))
    end
  end
end
