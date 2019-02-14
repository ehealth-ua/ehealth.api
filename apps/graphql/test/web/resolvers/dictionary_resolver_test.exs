defmodule GraphQLWeb.DictionaryResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: true

  import Core.Factories

  alias Absinthe.Relay.Node
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
          databaseId
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

  describe "update dictionary" do
    test "success", %{conn: conn} do
      %{id: id} = insert(:il, :dictionary)
      labels = ["ADMIN", "SYSTEM", "EXTERNAL"]

      dictionary_params = %{
        id: Node.to_global_id("Dictionary", id),
        labels: labels,
        values: Jason.encode!(%{"key" => "value"})
      }

      {resp_body, resp_entity} = call_update_dictionary(conn, dictionary_params)

      refute resp_body["errors"]
      assert %{"databaseId" => ^id, "values" => %{"key" => "value"}} = resp_entity
      assert %Dictionary{labels: ^labels} = Dictionaries.get_by_id(id)
    end

    test "fails to update with invalid label", %{conn: conn} do
      %{id: id} = insert(:il, :dictionary)

      dictionary_params = %{
        id: Node.to_global_id("Dictionary", id),
        labels: ["INVALID_LABEL"]
      }

      {resp_body, resp_entity} = call_update_dictionary(conn, dictionary_params)

      refute resp_entity

      assert [
               %{
                 "path" => ["updateDictionary"],
                 "extensions" => %{
                   "code" => "UNPROCESSABLE_ENTITY",
                   "exception" => %{
                     "inputErrors" => [
                       %{
                         "message" => "has an invalid entry",
                         "path" => ["labels"]
                       }
                     ]
                   }
                 }
               }
             ] = resp_body["errors"]
    end

    test "fails to update on duplicated labels", %{conn: conn} do
      %{id: id} = insert(:il, :dictionary, is_active: true)

      dictionary_params = %{
        id: Node.to_global_id("Dictionary", id),
        labels: ["SYSTEM", "SYSTEM"]
      }

      {resp_body, resp_entity} = call_update_dictionary(conn, dictionary_params)

      refute resp_entity

      assert [
               %{
                 "path" => ["updateDictionary"],
                 "extensions" => %{
                   "code" => "UNPROCESSABLE_ENTITY",
                   "exception" => %{
                     "inputErrors" => [
                       %{
                         "message" => "Labels are duplicated",
                         "path" => ["labels"]
                       }
                     ]
                   }
                 }
               }
             ] = resp_body["errors"]
    end

    test "fails to rename dictionary", %{conn: conn} do
      %{id: id} = insert(:il, :dictionary, name: "TEST_DICTIONARY", is_active: true)

      dictionary_params = %{
        id: Node.to_global_id("Dictionary", id),
        name: "NEW_NAME"
      }

      {resp_body, resp_entity} = call_update_dictionary(conn, dictionary_params)

      refute resp_entity

      assert [
               %{
                 "path" => ["updateDictionary"],
                 "extensions" => %{
                   "code" => "UNPROCESSABLE_ENTITY",
                   "exception" => %{
                     "inputErrors" => [
                       %{
                         "message" => "Name can't be changed",
                         "path" => ["name"]
                       }
                     ]
                   }
                 }
               }
             ] = resp_body["errors"]
    end

    test "fails to update deactivated dictionary", %{conn: conn} do
      %{id: id} = insert(:il, :dictionary, name: "TEST_DICTIONARY", is_active: false)

      dictionary_params = %{
        id: Node.to_global_id("Dictionary", id),
        values: Jason.encode!(%{"key" => "value"})
      }

      {resp_body, resp_entity} = call_update_dictionary(conn, dictionary_params)

      refute resp_entity

      assert [
               %{
                 "path" => ["updateDictionary"],
                 "extensions" => %{
                   "code" => "UNPROCESSABLE_ENTITY",
                   "exception" => %{
                     "inputErrors" => [
                       %{
                         "message" => "Deactivated dictionary is not allowed to be updated",
                         "options" => %{},
                         "path" => ["isActive"]
                       }
                     ]
                   }
                 }
               }
             ] = resp_body["errors"]
    end

    test "fails to update on empty values", %{conn: conn} do
      %{id: id} = insert(:il, :dictionary, values: %{"key" => "value"})

      dictionary_params = %{
        id: Node.to_global_id("Dictionary", id),
        values: Jason.encode!(%{})
      }

      {resp_body, resp_entity} = call_update_dictionary(conn, dictionary_params)

      refute resp_entity

      assert [
               %{
                 "path" => ["updateDictionary"],
                 "extensions" => %{
                   "code" => "UNPROCESSABLE_ENTITY",
                   "exception" => %{
                     "inputErrors" => [
                       %{
                         "message" => "Values should not be empty",
                         "options" => %{},
                         "path" => ["values"]
                       }
                     ]
                   }
                 }
               }
             ] = resp_body["errors"]
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
