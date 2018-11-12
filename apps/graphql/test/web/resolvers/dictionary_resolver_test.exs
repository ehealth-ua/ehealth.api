defmodule GraphQLWeb.DictionaryResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: true

  import Core.Factories

  alias Core.Dictionaries
  alias Core.Dictionaries.Dictionary

  @list_query """
    query DictionartiesQuery($first: Int!, $filter: DictionaryFilter) {
      dictionaries(first: $first, filter: $filter) {
        pageInfo {
          startCursor
          endCursor
          hasPreviousPage
          hasNextPage
        }
        nodes {
          databaseId
          name
          isActive
          labels
          values
        }
      }
    }
  """

  @update_dictionary_query """
    mutation UpdateDictionary($input: UpdateDictionaryInput!) {
      updateDictionary(input: $input){
        dictionary {
          name
          isActive
          labels
          values
        }
      }
    }
  """

  describe "list dictionaries" do
    setup do
      insert_list(7, :il, :dictionary)
      insert_list(3, :il, :dictionary, is_active: false, labels: ["SOME_OPTION", "INTERNAL"])
      insert(:il, :dictionary, name: "TEST_DICTIONARY")

      :ok
    end

    test "list active items", %{conn: conn} do
      {resp_body, resp_entities, page_info} = call_list_dictionary(conn, %{first: 5, filter: %{is_active: true}})

      refute resp_body["errors"]
      assert 5 == length(resp_entities)
      assert %{"hasNextPage" => true, "hasPreviousPage" => false} = page_info
    end

    test "list by name", %{conn: conn} do
      {resp_body, resp_entities, page_info} = call_list_dictionary(conn, %{first: 10, filter: %{name: "est_dict"}})

      refute resp_body["errors"]
      assert [%{"name" => "TEST_DICTIONARY"}] = resp_entities
      assert %{"hasNextPage" => false, "hasPreviousPage" => false} = page_info
    end

    test "list inactive with label", %{conn: conn} do
      {resp_body, resp_entities, page_info} =
        call_list_dictionary(conn, %{first: 5, filter: %{is_active: false, label: "INTERNAL"}})

      refute resp_body["errors"]
      assert 3 == length(resp_entities)
      assert %{"hasNextPage" => false, "hasPreviousPage" => false} = page_info
    end

    test "not found by label search", %{conn: conn} do
      {resp_body, resp_entities, _} = call_list_dictionary(conn, %{first: 10, filter: %{label: "NON_EXISTENT_LABEL"}})

      refute resp_body["errors"]
      assert [] == resp_entities
    end
  end

  describe "update or create dictionary" do
    test "success create", %{conn: conn} do
      dictionary_name = "PHONE_TYPE"
      labels = ["SYSTEM", "EXTERNAL"]
      values = %{"MOBILE" => "мобільний", "LAND_LINE" => "стаціонарний"}

      dictionary_params = %{
        name: dictionary_name,
        is_active: true,
        labels: labels,
        values: Jason.encode!(values)
      }

      {resp_body, resp_entity} = call_update_dictionary(conn, dictionary_params)

      refute resp_body["errors"]
      assert %{"isActive" => true, "labels" => labels, "name" => dictionary_name, "values" => values} == resp_entity
      assert %Dictionary{name: ^dictionary_name} = Dictionaries.get_dictionary(dictionary_name)
    end

    test "success update", %{conn: conn} do
      dictionary_name = "PHONE_TYPE"
      insert(:il, :dictionary, name: dictionary_name, is_active: true)

      dictionary_params = %{
        name: dictionary_name,
        is_active: false
      }

      {resp_body, resp_entity} = call_update_dictionary(conn, dictionary_params)

      refute resp_body["errors"]
      assert %{"isActive" => false, "name" => ^dictionary_name} = resp_entity
      assert %Dictionary{name: ^dictionary_name, is_active: false} = Dictionaries.get_dictionary(dictionary_name)
    end
  end

  defp call_list_dictionary(conn, variables) do
    resp_body =
      conn
      |> post_query(@list_query, variables)
      |> json_response(200)

    resp_entities = get_in(resp_body, ~w(data dictionaries nodes))
    page_info = get_in(resp_body, ~w(data dictionaries pageInfo))

    {resp_body, resp_entities, page_info}
  end

  defp call_update_dictionary(conn, dictionary_params) do
    variables = %{
      input: dictionary_params
    }

    resp_body =
      conn
      |> put_client_id()
      |> put_consumer_id()
      |> post_query(@update_dictionary_query, variables)
      |> json_response(200)

    resp_entity = get_in(resp_body, ~w(data updateDictionary dictionary))

    {resp_body, resp_entity}
  end
end
