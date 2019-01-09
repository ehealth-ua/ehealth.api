defmodule GraphQLWeb.PersonResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: true

  import Core.Factories
  import Mox

  alias Ecto.UUID
  alias Absinthe.Relay.Node

  @person_query """
    query PersonQuery($id: ID!) {
      person(id: $id) {
        id
        databaseId
        firstName
        lastName
        secondName
        birthDate
        gender
        status
        birthCountry
        birthSettlement
        taxId
        unzr
        preferredWayCommunication
        insertedAt
        documents {
          type
          number
          issuedBy
          issuedAt
        }
        authenticationMethods {
          type
          phoneNumber
        }
        addresses {
          type
          country
          area
          region
          settlement
          settlementType
          settlementId
          streetType
          street
          building
          apartment
          zip
        }
        phones {
          type
          number
        }
        # declarations
      }
    }
  """

  @person_list_query """
    query PersonsListQuery($filter: PersonFilter, $orderBy: PersonOrderBy){
      persons(first: 10, filter: $filter, orderBy: $orderBy){
        nodes{
          id
          databaseId
          firstName
          lastName
          secondName
          birthDate
          gender
          status
        }
      }
    }
  """

  setup :verify_on_exit!

  setup context do
    conn = put_scope(context.conn, "person:read person:list")

    {:ok, %{conn: conn}}
  end

  describe "list" do
    test "success responds empty with empty params", %{conn: conn} do
      variables = %{filter: %{personal: %{}, documents: %{}}}

      resp_body =
        conn
        |> post_query(@person_list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data persons nodes))

      refute resp_body["errors"]
      assert [] == resp_entities
    end

    test "success with search params", %{conn: conn} do
      expect(RPCWorkerMock, :run, fn _, _, :search_persons, _ ->
        {:ok, build_list(50, :mpi_person)}
      end)

      variables = %{
        filter: %{
          personal: %{authentication_method: %{phone_number: "+380971234567"}, birth_date: "1990-10-10"},
          documents: %{tax_id: "123456", number: "123456"}
        },
        order_by: "TAX_ID_ASC"
      }

      resp_body =
        conn
        |> post_query(@person_list_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data persons nodes))

      refute resp_body["errors"]
      assert [] != resp_entities
    end
  end

  describe "get by id" do
    test "success", %{conn: conn} do
      database_id = UUID.generate()
      id = Node.to_global_id("Person", database_id)

      expect(RPCWorkerMock, :run, fn _, _, :get_person_by_id, _ ->
        {:ok, build(:mpi_person, id: database_id)}
      end)

      variables = %{id: id}

      resp_body =
        conn
        |> post_query(@person_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data person))

      refute resp_body["errors"]
      assert id == resp_entity["id"]
      assert database_id == resp_entity["databaseId"]

      assert Enum.all?(
               ~w(firstName lastName secondName birthDate gender status birthCountry birthSettlement taxId unzr preferredWayCommunication insertedAt documents addresses phones authenticationMethods),
               &Map.has_key?(resp_entity, &1)
             )

      Enum.each(resp_entity["documents"], fn document ->
        assert Enum.all?(~w(type number issuedBy issuedAt), &Map.has_key?(document, &1))
      end)

      Enum.each(resp_entity["authenticationMethods"], fn authentication_method ->
        assert Enum.all?(~w(type phoneNumber), &Map.has_key?(authentication_method, &1))
      end)

      Enum.each(resp_entity["addresses"], fn address ->
        assert Enum.all?(
                 ~w(type country area region settlement settlementType settlementId streetType street building apartment zip),
                 &Map.has_key?(address, &1)
               )
      end)

      Enum.each(resp_entity["phones"], fn phone ->
        assert Enum.all?(~w(type number), &Map.has_key?(phone, &1))
      end)
    end

    test "not found", %{conn: conn} do
      database_id = UUID.generate()
      id = Node.to_global_id("Person", database_id)

      expect(RPCWorkerMock, :run, fn _, _, :get_person_by_id, _ -> nil end)

      variables = %{id: id}

      resp_body =
        conn
        |> post_query(@person_query, variables)
        |> json_response(200)

      %{"errors" => [error]} = resp_body

      refute get_in(resp_body, ~w(data person))
      assert "NOT_FOUND" == error["extensions"]["code"]
    end
  end
end
