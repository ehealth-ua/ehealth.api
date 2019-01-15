defmodule GraphQLWeb.LegalEntityMergeJobResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: true

  import Core.Expectations.Signature
  import Core.Factories
  import Mox

  alias Absinthe.Relay.Node
  alias BSON.ObjectId
  alias Core.LegalEntities.LegalEntity
  alias Ecto.UUID
  alias TasKafka.Jobs, as: TasKafkaJobs

  setup :verify_on_exit!

  @type_merge_legal_entities Jobs.type(:merge_legal_entities)

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

      signed_content = merged_signed_content(from, to)

      drfo_signed_content(signed_content, tax_id)
      drfo_signed_content(signed_content, tax_id)

      job =
        conn
        |> post_query(@query, input_signed_content(signed_content))
        |> json_response(200)
        |> get_in(~w(data mergeLegalEntities legalEntityMergeJob))

      assert "PENDING" == job["status"]
      assert Map.has_key?(job, "endedAt")
      refute job["endedAt"]

      resp =
        conn
        |> post_query(@query, input_signed_content(signed_content))
        |> json_response(200)

      assert %{"message" => "Merge Legal Entity job is already created with id " <> id} = hd(resp["errors"])

      query = """
        query GetLegalEntityMergeJobQuery($id: ID) {
          legalEntityMergeJob(id: $id) {
            status
          }
        }
      """

      assert "PENDING" ==
               conn
               |> put_scope("legal_entity_merge_job:read")
               |> post_query(query, %{id: id})
               |> json_response(200)
               |> get_in(~w(data legalEntityMergeJob status))
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
      {:ok, %{conn: put_scope(conn, "legal_entity_merge_job:read")}}
    end

    test "filter by status and mergedToLegalEntity", %{conn: conn} do
      merged_to = insert(:prm, :legal_entity)
      {:ok, job_id1, _} = create_job(insert(:prm, :legal_entity), merged_to)
      {:ok, job_id2, _} = create_job(insert(:prm, :legal_entity), merged_to)
      {:ok, job_id3, _} = create_job(insert(:prm, :legal_entity), merged_to)
      {:ok, job_id4, _} = create_job(insert(:prm, :legal_entity), insert(:prm, :legal_entity))
      create_job(insert(:prm, :legal_entity), insert(:prm, :legal_entity))
      result = %{related_legal_entity_id: UUID.generate()}
      TasKafkaJobs.processed(job_id1, result)
      TasKafkaJobs.processed(job_id2, result)
      TasKafkaJobs.processed(job_id3, result)
      TasKafkaJobs.processed(job_id4, result)

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
          status: "PROCESSED",
          mergedToLegalEntity: %{
            edrpou: merged_to.edrpou
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
            edrpou: merged_to.edrpou
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

    test "order_by", %{conn: conn} do
      merged_to = insert(:prm, :legal_entity)
      {:ok, job_id_first, _} = create_job(insert(:prm, :legal_entity), merged_to)
      create_job(insert(:prm, :legal_entity), merged_to)
      create_job(insert(:prm, :legal_entity), merged_to)
      {:ok, job_id_last, _} = create_job(insert(:prm, :legal_entity), merged_to)

      query = """
        query ListLegalEntityMergeJobsQuery(
          $first: Int!,
          $filter: LegalEntityMergeJobFilter!,
          $order_by: LegalEntityMergeJobOrderBy!
        ){
          legalEntityMergeJobs(first: $first, filter: $filter, order_by: $order_by) {
            nodes {
              id
              startedAt
            }
          }
        }
      """

      variables = %{
        first: 10,
        filter: %{
          mergedToLegalEntity: %{
            edrpou: merged_to.edrpou
          }
        },
        order_by: "STARTED_AT_DESC"
      }

      resp =
        conn
        |> post_query(query, variables)
        |> json_response(200)
        |> get_in(~w(data legalEntityMergeJobs nodes))

      assert Node.to_global_id("LegalEntityMergeJob", job_id_last) == hd(resp)["id"]

      variables = %{
        first: 10,
        filter: %{
          mergedToLegalEntity: %{
            edrpou: merged_to.edrpou
          }
        },
        order_by: "STARTED_AT_ASC"
      }

      resp =
        conn
        |> post_query(query, variables)
        |> json_response(200)
        |> get_in(~w(data legalEntityMergeJobs nodes))

      assert Node.to_global_id("LegalEntityMergeJob", job_id_first) == hd(resp)["id"]
    end
  end

  describe "get by id" do
    setup %{conn: conn} do
      {:ok, %{conn: put_scope(conn, "legal_entity_merge_job:read")}}
    end

    test "success", %{conn: conn} do
      merged_to = insert(:prm, :legal_entity)
      merged_from = insert(:prm, :legal_entity)

      meta = %{
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
      }

      {:ok, job_id, _} = create_job(meta)
      result = %{related_legal_entity_id: UUID.generate()}
      TasKafkaJobs.processed(job_id, result)
      id = Node.to_global_id("LegalEntityMergeJob", job_id)

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

      assert meta["merged_to_legal_entity"] == resp["mergedToLegalEntity"]
      assert meta["merged_from_legal_entity"] == resp["mergedFromLegalEntity"]
      assert "PROCESSED" == resp["status"]
      assert Jason.encode!(result) == resp["result"]
    end

    test "job not found", %{conn: conn} do
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

  defp create_job(merged_from, merged_to) do
    %{
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
    }
    |> create_job()
  end

  defp create_job(meta) do
    {:ok, job} = TasKafkaJobs.create(meta, @type_merge_legal_entities)
    {:ok, ObjectId.encode!(job._id), job}
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
