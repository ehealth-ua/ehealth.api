defmodule GraphQLWeb.LegalEntityDeactivationJobResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: true

  import Core.Factories
  import Mox

  alias Absinthe.Relay.Node
  alias BSON.ObjectId
  alias Core.LegalEntities.LegalEntity
  alias Ecto.UUID
  alias TasKafka.Job
  alias TasKafka.Jobs, as: TasKafkaJobs

  setup :verify_on_exit!

  @legal_entity_deactivation_type Jobs.type(:legal_entity_deactivation)

  @query """
    mutation DeactivateLegalEntityMutation($input: DeactivateLegalEntityInput!) {
      deactivateLegalEntity(input: $input) {
        legalEntityDeactivationJob {
          id
          status
          endedAt
        }
      }
    }
  """

  setup %{conn: conn} do
    consumer_id = UUID.generate()

    party = insert(:prm, :party)
    insert(:prm, :party_user, party: party, user_id: consumer_id)

    conn =
      conn
      |> put_scope("legal_entity:deactivate")
      |> put_consumer_id(consumer_id)

    {:ok, %{conn: conn}}
  end

  describe "deactivate legal entity" do
    test "success", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)

      job =
        conn
        |> post_query(@query, input_legal_entity_id(legal_entity.id))
        |> json_response(200)
        |> get_in(~w(data deactivateLegalEntity legalEntityDeactivationJob))

      pending_status =
        :pending
        |> Job.status()
        |> Job.status_to_string()
        |> String.upcase()

      assert pending_status == job["status"]
      assert Map.has_key?(job, "endedAt")
      refute job["endedAt"]

      resp =
        conn
        |> post_query(@query, input_legal_entity_id(legal_entity.id))
        |> json_response(200)

      assert %{"message" => "Legal Entity deactivation job is already created with id " <> id} = hd(resp["errors"])

      query = """
        query GetLegalEntityDeactivationJobQuery($id: ID) {
          legalEntityDeactivationJob(id: $id) {
            status
          }
        }
      """

      pending_status =
        :pending
        |> Job.status()
        |> Job.status_to_string()
        |> String.upcase()

      assert pending_status ==
               conn
               |> put_scope("legal_entity_deactivation_job:read")
               |> post_query(query, %{id: id})
               |> json_response(200)
               |> get_in(~w(data legalEntityDeactivationJob status))
    end

    test "invalid scope", %{conn: conn} do
      resp =
        conn
        |> put_scope("scope:not-allowed")
        |> post_query(@query, input_legal_entity_id(""))
        |> json_response(200)

      assert match?(%{"deactivateLegalEntity" => nil}, resp["data"])
      assert Enum.any?(resp["errors"], &match?(%{"extensions" => %{"code" => "FORBIDDEN"}}, &1))
    end

    test "deactivate legal entity that does not exist", %{conn: conn} do
      resp =
        conn
        |> post_query(@query, input_legal_entity_id(Ecto.UUID.generate()))
        |> json_response(200)

      assert match?(%{"deactivateLegalEntity" => nil}, resp["data"])
      assert Enum.any?(resp["errors"], &match?(%{"message" => "LegalEntity not found"}, &1))
    end

    test "deactivate legal entity with status CLOSED", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, status: LegalEntity.status(:closed))

      resp =
        conn
        |> post_query(@query, input_legal_entity_id(legal_entity.id))
        |> json_response(200)

      assert match?(%{"deactivateLegalEntity" => nil}, resp["data"])
      assert Enum.any?(resp["errors"], &match?(%{"message" => "Legal entity is not ACTIVE and cannot be updated"}, &1))
    end

    test "deactivate legal entity that is not reviewed", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity, nhs_reviewed: false)

      resp =
        conn
        |> post_query(@query, input_legal_entity_id(legal_entity.id))
        |> json_response(200)

      assert match?(%{"deactivateLegalEntity" => nil}, resp["data"])
      assert Enum.any?(resp["errors"], &match?(%{"message" => "Legal entity should be reviewed first"}, &1))
    end
  end

  describe "get list" do
    setup %{conn: conn} do
      {:ok, %{conn: put_scope(conn, "legal_entity_deactivation_job:read")}}
    end

    test "filter by status and legal_entity_id", %{conn: conn} do
      legal_entity1 = insert(:prm, :legal_entity)
      legal_entity2 = insert(:prm, :legal_entity)
      {:ok, job_id1, _} = create_job(legal_entity1.id)
      TasKafkaJobs.processed(job_id1, :done)
      {:ok, job_id2, _} = create_job(legal_entity1.id)
      TasKafkaJobs.processed(job_id2, :done)
      {:ok, job_id3, _} = create_job(legal_entity1.id)
      TasKafkaJobs.processed(job_id3, :done)
      {:ok, job_id4, _} = create_job(legal_entity1.id)
      TasKafkaJobs.failed(job_id4, :error)
      {:ok, job_id5, _} = create_job(legal_entity2.id)
      TasKafkaJobs.processed(job_id5, :done)

      query = """
        query ListLegalEntityDeactivationJobsQuery(
          $first: Int!,
          $filter: LegalEntityDeactivationJobFilter!,
          $order_by: LegalEntityDeactivationJobOrderBy!
        ){
          legalEntityDeactivationJobs(first: $first, filter: $filter, order_by: $order_by) {
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
              legal_entity_id
            }
          }
        }
      """

      variables = %{
        first: 2,
        filter: %{
          status: "PROCESSED",
          legal_entity_id: legal_entity1.id
        },
        order_by: "STARTED_AT_DESC",
        after: nil
      }

      resp =
        conn
        |> post_query(query, variables)
        |> json_response(200)
        |> get_in(~w(data legalEntityDeactivationJobs))

      assert 2 == length(resp["nodes"])
      assert resp["pageInfo"]["hasNextPage"]
      refute resp["pageInfo"]["hasPreviousPage"]

      query = """
        query ListLegalEntitiesQuery(
          $first: Int!,
          $filter: LegalEntityDeactivationJobFilter!,
          $order_by: LegalEntityDeactivationJobOrderBy!,
          $after: String!
        ){
          legalEntityDeactivationJobs(first: $first, filter: $filter, order_by: $order_by, after: $after) {
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
        first: 3,
        filter: %{
          status: "PROCESSED",
          legal_entity_id: legal_entity1.id
        },
        order_by: "STARTED_AT_ASC",
        after: resp["pageInfo"]["endCursor"]
      }

      resp =
        conn
        |> post_query(query, variables)
        |> json_response(200)
        |> get_in(~w(data legalEntityDeactivationJobs))

      assert 1 == length(resp["nodes"])
      refute resp["pageInfo"]["hasNextPage"]
      assert resp["pageInfo"]["hasPreviousPage"]
    end

    test "order_by", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      {:ok, job_id1, _} = create_job(legal_entity.id)
      TasKafkaJobs.processed(job_id1, :done)
      {:ok, job_id2, _} = create_job(legal_entity.id)
      TasKafkaJobs.processed(job_id2, :done)
      {:ok, job_id3, _} = create_job(legal_entity.id)
      TasKafkaJobs.processed(job_id3, :done)
      {:ok, job_id4, _} = create_job(legal_entity.id)
      TasKafkaJobs.processed(job_id4, :done)

      query = """
        query ListLegalEntityDeactivationJobsQuery(
          $first: Int!,
          $filter: LegalEntityDeactivationJobFilter!,
          $order_by: LegalEntityDeactivationJobOrderBy!
        ){
          legalEntityDeactivationJobs(first: $first, filter: $filter, order_by: $order_by) {
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
          legal_entity_id: legal_entity.id
        },
        order_by: "STARTED_AT_DESC"
      }

      resp =
        conn
        |> post_query(query, variables)
        |> json_response(200)
        |> get_in(~w(data legalEntityDeactivationJobs nodes))

      assert Node.to_global_id("LegalEntityDeactivationJob", job_id4) == hd(resp)["id"]

      variables = %{
        first: 10,
        filter: %{
          legal_entity_id: legal_entity.id
        },
        order_by: "STARTED_AT_ASC"
      }

      resp =
        conn
        |> post_query(query, variables)
        |> json_response(200)
        |> get_in(~w(data legalEntityDeactivationJobs nodes))

      assert Node.to_global_id("LegalEntityDeactivationJob", job_id1) == hd(resp)["id"]
    end
  end

  describe "get by id" do
    setup %{conn: conn} do
      {:ok, %{conn: put_scope(conn, "legal_entity_deactivation_job:read")}}
    end

    test "success", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      {:ok, job_id, _} = create_job(legal_entity.id)
      TasKafkaJobs.processed(job_id, :done)
      id = Node.to_global_id("LegalEntityDeactivationJob", job_id)

      query = """
        query GetLegalEntityDeactivationJobQuery($id: ID) {
          legalEntityDeactivationJob(id: $id) {
            id
            status
            result
            startedAt
            endedAt
            result
            legal_entity_id
          }
        }
      """

      variables = %{id: id}

      resp =
        conn
        |> post_query(query, variables)
        |> json_response(200)
        |> get_in(~w(data legalEntityDeactivationJob))

      assert legal_entity.id == resp["legal_entity_id"]
      assert "PROCESSED" == resp["status"]
      assert Jason.encode!(:done) == resp["result"]
    end

    test "job not found", %{conn: conn} do
      query = """
        query GetLegalEntityDeactivationJobQuery($id: ID) {
          legalEntityDeactivationJob(id: $id) {
            id
          }
        }
      """

      variables = %{id: Node.to_global_id("LegalEntityDeactivationJob", "invalid-id")}

      resp =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      assert match?(%{"legalEntityDeactivationJob" => nil}, resp["data"])
    end
  end

  defp create_job(legal_entity_id) do
    {:ok, job} = TasKafkaJobs.create(%{"legal_entity_id" => legal_entity_id}, @legal_entity_deactivation_type)
    {:ok, ObjectId.encode!(job._id), job}
  end

  defp input_legal_entity_id(id) do
    %{
      input: %{
        id: Node.to_global_id("LegalEntityDeactivationJob", id)
      }
    }
  end
end
