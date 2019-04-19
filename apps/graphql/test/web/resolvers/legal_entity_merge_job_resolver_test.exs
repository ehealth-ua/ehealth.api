defmodule GraphQL.LegalEntityMergeJobResolverTest do
  @moduledoc false

  use GraphQL.ConnCase, async: true

  import Core.Expectations.Signature
  import Core.Factories
  import Mox

  alias Absinthe.Relay.Node
  alias Core.LegalEntities.LegalEntity
  alias Jobs.LegalEntityMergeJob
  alias Ecto.UUID
  alias Jobs.Jabba.Client, as: JabbaClient

  setup :verify_on_exit!

  @query """
    mutation MergeLegalEntitiesMutation($input: MergeLegalEntitiesInput!) {
      mergeLegalEntities(input: $input) {
        legalEntityMergeJob {
          id
          status
          endedAt
        }
      }
    }
  """

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

  describe "merge legal entities" do
    test "success", %{conn: conn, tax_id: tax_id} do
      from = insert(:prm, :legal_entity)
      to = insert(:prm, :legal_entity)
      insert(:prm, :related_legal_entity, merged_to: to)
      job = job("merge_legal_entities", "PENDING", to, from)

      expect(RPCWorkerMock, :run, fn _, _, :create_job, [tasks, _type, _opts] ->
        assert 1 == length(tasks)
        %{name: name, callback: {_, m, f, a}} = hd(tasks)
        assert LegalEntityMergeJob = m
        assert :merge = f
        assert is_map(hd(a))
        assert "Merge legal entity" == name

        {:ok, job}
      end)

      signed_content = merged_signed_content(from, to)

      drfo_signed_content(signed_content, tax_id)

      job =
        conn
        |> post_query(@query, input_signed_content(signed_content))
        |> json_response(200)
        |> get_in(~w(data mergeLegalEntities legalEntityMergeJob))

      assert "PENDING" == job["status"]
      assert Map.has_key?(job, "endedAt")
      refute job["endedAt"]

      # ToDo: implement in Jabba job deduplication
      #      drfo_signed_content(signed_content, tax_id)
      #      resp =
      #        conn
      #        |> post_query(@query, input_signed_content(signed_content))
      #        |> json_response(200)
      #      assert %{"message" => "Merge Legal Entity job is already created with id " <> id} = hd(resp["errors"])
    end

    test "invalid client_id", %{conn: conn, tax_id: tax_id} do
      from = insert(:prm, :legal_entity)
      to = insert(:prm, :legal_entity)
      insert(:prm, :related_legal_entity, merged_to: to)

      signed_content = merged_signed_content(from, to)
      drfo_signed_content(signed_content, tax_id)

      resp =
        conn
        |> put_client_id(UUID.generate())
        |> post_query(@query, input_signed_content(signed_content))
        |> json_response(200)

      refute get_in(resp, ~w(data legalEntityMergeJobs))

      assert Enum.any?(resp["errors"], &match?(%{"extensions" => %{"code" => "NOT_FOUND"}}, &1))
    end

    test "invalid scope", %{conn: conn} do
      resp =
        conn
        |> put_scope("scope:not-allowed")
        |> post_query(@query, input_signed_content(""))
        |> json_response(200)

      assert match?(%{"mergeLegalEntities" => nil}, resp["data"])
      assert Enum.any?(resp["errors"], &match?(%{"extensions" => %{"code" => "FORBIDDEN"}}, &1))
    end

    test "merged from legal entity with status CLOSED", %{conn: conn, tax_id: tax_id} do
      from = insert(:prm, :legal_entity, status: LegalEntity.status(:closed))
      to = insert(:prm, :legal_entity)

      signed_content = merged_signed_content(from, to)
      drfo_signed_content(signed_content, tax_id)

      resp =
        conn
        |> post_query(@query, input_signed_content(signed_content))
        |> json_response(200)

      assert match?(%{"mergeLegalEntities" => nil}, resp["data"])
      assert Enum.any?(resp["errors"], &match?(%{"message" => "Merged from legal entity must be active"}, &1))
    end

    test "merged to legal entity with status CLOSED", %{conn: conn, tax_id: tax_id} do
      from = insert(:prm, :legal_entity)
      to = insert(:prm, :legal_entity, status: LegalEntity.status(:closed))

      signed_content = merged_signed_content(from, to)
      drfo_signed_content(signed_content, tax_id)

      resp =
        conn
        |> post_query(@query, input_signed_content(signed_content))
        |> json_response(200)

      assert match?(%{"mergeLegalEntities" => nil}, resp["data"])
      assert Enum.any?(resp["errors"], &match?(%{"message" => "Merged to legal entity must be active"}, &1))
    end

    test "merge with invalid legal entity type", %{conn: conn, tax_id: tax_id} do
      from = insert(:prm, :legal_entity)
      to1 = insert(:prm, :legal_entity, type: LegalEntity.type(:mis))
      to2 = insert(:prm, :legal_entity, type: LegalEntity.type(:pharmacy))

      Enum.each([to1, to2], fn to ->
        signed_content = merged_signed_content(from, to)
        drfo_signed_content(signed_content, tax_id)

        resp =
          conn
          |> post_query(@query, input_signed_content(signed_content))
          |> json_response(200)

        assert match?(%{"mergeLegalEntities" => nil}, resp["data"])
        assert Enum.any?(resp["errors"], &match?(%{"message" => "Invalid legal entity type"}, &1))
      end)
    end

    test "merged to already merged", %{conn: conn, tax_id: tax_id} do
      from = insert(:prm, :legal_entity)
      to = insert(:prm, :legal_entity)
      insert(:prm, :related_legal_entity, merged_from: to)

      signed_content = merged_signed_content(from, to)
      drfo_signed_content(signed_content, tax_id)

      resp =
        conn
        |> post_query(@query, input_signed_content(signed_content))
        |> json_response(200)

      assert match?(%{"mergeLegalEntities" => nil}, resp["data"])

      assert Enum.any?(
               resp["errors"],
               &match?(%{"message" => "Merged to legal entity is in the process of reorganization itself"}, &1)
             )
    end

    test "merged from already merged", %{conn: conn, tax_id: tax_id} do
      from = insert(:prm, :legal_entity)
      to = insert(:prm, :legal_entity)
      insert(:prm, :related_legal_entity, merged_from: from)

      signed_content = merged_signed_content(from, to)
      drfo_signed_content(signed_content, tax_id)

      resp =
        conn
        |> post_query(@query, input_signed_content(signed_content))
        |> json_response(200)

      assert match?(%{"mergeLegalEntities" => nil}, resp["data"])

      assert Enum.any?(
               resp["errors"],
               &match?(%{"message" => "Merged from legal entity is already in the process of reorganization"}, &1)
             )
    end
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
        assert type == filter[:type]
        assert status == filter[:status]
        assert %{edrpou: edrpou} == filter[:merged_to_legal_entity]
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
            edrpou: edrpou
          }
        },
        order_by: "STARTED_AT_DESC"
      }

      resp =
        conn
        |> post_query(query, variables)
        |> json_response(200)
        |> get_in(~w(data legalEntityMergeJobs))

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

  defp merged_signed_content(merged_from, merged_to) do
    %{
      "merged_from_legal_entity" => %{
        "id" => merged_from.id,
        "name" => merged_from.name,
        "edrpou" => merged_from.edrpou
      },
      "merged_to_legal_entity" => %{
        "id" => merged_to.id,
        "name" => merged_to.name,
        "edrpou" => merged_to.edrpou
      },
      "reason" => "Because I can"
    }
  end

  defp input_signed_content(content) do
    %{
      input: %{
        signedContent: %{
          content: content |> Jason.encode!() |> Base.encode64(),
          encoding: "BASE64"
        }
      }
    }
  end
end
