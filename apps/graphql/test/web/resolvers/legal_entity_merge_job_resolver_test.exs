defmodule GraphQL.LegalEntityMergeJobResolverTest do
  @moduledoc false

  use GraphQL.ConnCase, async: true

  import Core.Factories
  import Mox

  alias Absinthe.Relay.Node
  alias Ecto.UUID
  alias Jobs.Jabba.Client, as: JabbaClient

  setup :verify_on_exit!

  setup %{conn: conn} do
    user_id = UUID.generate()
    tax_id = random_tax_id()

    party = insert(:prm, :party, tax_id: tax_id)
    insert(:prm, :party_user, party: party, user_id: user_id)
    %{id: client_id} = insert(:prm, :legal_entity, edrpou: tax_id)

    conn =
      conn
      |> put_scope("legal_entity:merge")
      |> put_drfo(tax_id)
      |> put_consumer_id(user_id)
      |> put_client_id(client_id)

    {:ok, %{conn: conn, tax_id: tax_id, client_id: client_id}}
  end

  describe "get list" do
    setup %{conn: conn} do
      merged_to = insert(:prm, :legal_entity)
      merged_from = insert(:prm, :legal_entity)
      status = "PROCESSED"
      type = JabbaClient.type(:merge_legal_entities)
      job = job(type, status, merged_to, merged_from)

      {:ok, %{conn: put_scope(conn, "legal_entity_merge_job:read"), job: job}}
    end

    test "filter by status and mergedToLegalEntity", %{conn: conn, job: job} do
      type = job.type
      status = job.status
      edrpou = get_in(job[:meta], ~w(merged_to_legal_entity edrpou))
      assert edrpou

      expect(RPCWorkerMock, :run, fn _, _, :search_jobs, args ->
        assert [filter, order_by, cursor] = args

        # filter for status
        assert {:status, :equal, ^status} = hd(filter)

        # filter for type
        assert {:type, :equal, ^type} = List.last(filter)

        # filter for jsonb field meta
        assert {{:meta, nil, value}, _} = List.pop_at(filter, 1)

        assert [
                 {:merged_to_legal_entity, nil, [{:edrpou, :equal, edrpou}, {:is_active, :equal, true}]}
               ] == value

        # order
        assert [desc: :started_at] == order_by
        assert {3, 0} == cursor

        {:ok, [job, job, job]}
      end)

      expect(RPCWorkerMock, :run, fn _, _, :search_jobs, _args -> {:ok, [job]} end)

      query = """
        query ListLegalEntityMergeJobsQuery(
          $first: Int!,
          $filter: LegalEntityMergeJobFilter!,
          $order_by: LegalEntityMergeJobOrderBy!
        ){
          legalEntityMergeJobs(first: $first, filter: $filter, order_by: $order_by) {
            pageInfo {
              startCursor
              endCursor
              hasPreviousPage
              hasNextPage
            }
            nodes {
              id
              status
              result
              startedAt
              endedAt
              result
              mergedToLegalEntity{
                id
                name
                edrpou
              }
              mergedFromLegalEntity{
                id
                name
                edrpou
              }
            }
          }
        }
      """

      variables = %{
        first: 2,
        filter: %{
          status: status,
          mergedToLegalEntity: %{
            edrpou: edrpou,
            is_active: true
          }
        },
        order_by: "STARTED_AT_DESC"
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      refute resp_body["errors"]

      resp = get_in(resp_body, ~w(data legalEntityMergeJobs))

      assert 2 == length(resp["nodes"])
      assert resp["pageInfo"]["hasNextPage"]
      refute resp["pageInfo"]["hasPreviousPage"]

      query = """
        query ListLegalEntitiesQuery(
          $first: Int!,
          $filter: LegalEntityMergeJobFilter!,
          $order_by: LegalEntityMergeJobOrderBy!,
          $after: String!
        ){
          legalEntityMergeJobs(first: $first, filter: $filter, order_by: $order_by, after: $after) {
            pageInfo {
              hasPreviousPage
              hasNextPage
            }
            nodes {
              id
              status
            }
          }
        }
      """

      variables = %{
        first: 2,
        filter: %{
          status: "PROCESSED",
          mergedToLegalEntity: %{
            edrpou: edrpou
          }
        },
        order_by: "STARTED_AT_ASC",
        after: resp["pageInfo"]["endCursor"]
      }

      resp =
        conn
        |> post_query(query, variables)
        |> json_response(200)
        |> get_in(~w(data legalEntityMergeJobs))

      assert 1 == length(resp["nodes"])
      refute resp["pageInfo"]["hasNextPage"]
      assert resp["pageInfo"]["hasPreviousPage"]
    end

    test "argument `first` not set", %{conn: conn} do
      query = """
        query ListLegalEntitiesQuery($after: String!){
          legalEntityMergeJobs(after: $after) {
            nodes {
              id
            }
          }
        }
      """

      variables = %{
        after: "some-cursor"
      }

      resp =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      assert Enum.any?(resp["errors"], &match?(%{"message" => "You must either supply `:first` or `:last`"}, &1))
    end
  end

  describe "get by id" do
    setup %{conn: conn} do
      {:ok, %{conn: put_scope(conn, "legal_entity_merge_job:read")}}
    end

    test "success", %{conn: conn} do
      merged_to = insert(:prm, :legal_entity)
      merged_from = insert(:prm, :legal_entity)
      job = job("merge_legal_entities", "PROCESSED", merged_to, merged_from)

      expect(RPCWorkerMock, :run, fn _, _, :get_job, args ->
        assert job.id == hd(args)

        {:ok, job}
      end)

      id = Node.to_global_id("LegalEntityMergeJob", job.id)

      query = """
        query GetLegalEntityMergeJobQuery($id: ID) {
          legalEntityMergeJob(id: $id) {
            id
            status
            result
            startedAt
            endedAt
            result
            mergedToLegalEntity{
              id
              name
              edrpou
            }
            mergedFromLegalEntity{
              id
              name
              edrpou
            }
          }
        }
      """

      variables = %{id: id}

      resp =
        conn
        |> post_query(query, variables)
        |> json_response(200)
        |> get_in(~w(data legalEntityMergeJob))

      assert job.meta["merged_to_legal_entity"] == resp["mergedToLegalEntity"]
      assert job.meta["merged_from_legal_entity"] == resp["mergedFromLegalEntity"]
      assert "PROCESSED" == resp["status"]
    end

    test "job not found", %{conn: conn} do
      expect(RPCWorkerMock, :run, fn _, _, :get_job, _args -> {:ok, nil} end)

      query = """
        query GetLegalEntityMergeJobQuery($id: ID) {
          legalEntityMergeJob(id: $id) {
            id
          }
        }
      """

      variables = %{id: Node.to_global_id("LegalEntityMergeJob", "invalid-id")}

      resp =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      assert match?(%{"legalEntityMergeJob" => nil}, resp["data"])
    end
  end

  defp job(type, status, merged_to, merged_from, ended_at \\ nil) do
    %{
      id: UUID.generate(),
      type: type,
      status: status,
      result: %{"success" => "ok"},
      meta: %{
        "merged_to_legal_entity" => %{
          "id" => merged_to.id,
          "name" => merged_to.name,
          "edrpou" => merged_to.edrpou
        },
        "merged_from_legal_entity" => %{
          "id" => merged_from.id,
          "name" => merged_from.name,
          "edrpou" => merged_from.edrpou
        }
      },
      inserted_at: DateTime.utc_now(),
      ended_at: ended_at
    }
  end
end
