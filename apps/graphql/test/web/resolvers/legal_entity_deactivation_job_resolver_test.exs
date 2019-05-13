defmodule GraphQL.LegalEntityDeactivationJobResolverTest do
  @moduledoc false

  use GraphQL.ConnCase, async: true

  import Core.Factories
  import Mox

  alias Absinthe.Relay.Node
  alias Core.LegalEntities.LegalEntity
  alias Ecto.UUID
  alias Jobs.LegalEntityDeactivationJob
  alias Jobs.Jabba.Client, as: JabbaClient

  setup :verify_on_exit!

  @query """
    mutation DeactivateLegalEntityMutation($input: DeactivateLegalEntityInput!) {
      deactivateLegalEntity(input: $input) {
        legalEntityDeactivationJob {
          id
          databaseId
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
      type = JabbaClient.type(:legal_entity_deactivation)
      status = "PENDING"
      job = job("legal_entity_deactivation", "PENDING", legal_entity)

      expect(RPCWorkerMock, :run, fn _, _, :create_job, [tasks, job_type, _opts] ->
        assert 1 == length(tasks)
        %{name: name, callback: {_, m, f, a}} = hd(tasks)
        assert LegalEntityDeactivationJob = m
        assert :deactivate = f
        assert is_list(a)
        assert type == job_type
        assert "Deactivate legal entity" == name

        {:ok, job}
      end)

      job =
        conn
        |> post_query(@query, input_legal_entity_id(legal_entity.id))
        |> json_response(200)
        |> get_in(~w(data deactivateLegalEntity legalEntityDeactivationJob))

      assert status == job["status"]
      assert Map.has_key?(job, "endedAt")
      refute job["endedAt"]
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
      legal_entity = insert(:prm, :legal_entity)
      type = JabbaClient.type(:legal_entity_deactivation)
      status = "PROCESSED"
      job = job("legal_entity_deactivation", "PENDING", legal_entity)
      edrpou = get_in(job[:meta], ~w(deactivated_legal_entity edrpou))
      assert edrpou

      expect(RPCWorkerMock, :run, fn _, _, :search_jobs, args ->
        assert [filter, order_by, cursor] = args

        # filter for status
        assert {:status, :equal, ^status} = hd(filter)

        # filter for type
        assert {:type, :equal, ^type} = List.last(filter)

        # filter for jsonb field meta
        assert {{:meta, nil, value}, _} = List.pop_at(filter, 1)
        assert [{:deactivated_legal_entity, nil, [{:edrpou, :equal, edrpou}]}] == value

        assert [desc: :started_at] == order_by
        assert {3, 0} == cursor

        {:ok, [job, job, job]}
      end)

      expect(RPCWorkerMock, :run, fn _, _, :search_jobs, _args -> {:ok, [job]} end)

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
              startedAt
              endedAt
              deactivatedLegalEntity {
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
          deactivated_legal_entity: %{
            edrpou: legal_entity.edrpou
          }
        },
        order_by: "STARTED_AT_DESC",
        after: nil
      }

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      refute resp_body["errors"]

      resp = get_in(resp_body, ~w(data legalEntityDeactivationJobs))

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
          deactivated_legal_entity: %{
            edrpou: legal_entity.edrpou
          }
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
  end

  describe "get by id" do
    setup %{conn: conn} do
      {:ok, %{conn: put_scope(conn, "legal_entity_deactivation_job:read")}}
    end

    test "success", %{conn: conn} do
      legal_entity = insert(:prm, :legal_entity)
      job = job("merge_legal_entities", "PROCESSED", legal_entity)

      expect(RPCWorkerMock, :run, fn _, _, :get_job, args ->
        assert job.id == hd(args)

        {:ok, job}
      end)

      id = Node.to_global_id("LegalEntityDeactivationJob", job.id)

      query = """
        query GetLegalEntityDeactivationJobQuery($id: ID) {
          legalEntityDeactivationJob(id: $id) {
            id
            status
            startedAt
            endedAt
            deactivatedLegalEntity{
              id
              name
              edrpou
            }
          }
        }
      """

      variables = %{id: id}

      resp_body =
        conn
        |> post_query(query, variables)
        |> json_response(200)

      refute resp_body["errors"]

      resp = get_in(resp_body, ~w(data legalEntityDeactivationJob))

      assert legal_entity.edrpou == resp["deactivatedLegalEntity"]["edrpou"]
      assert "PROCESSED" == resp["status"]
      refute resp["result"]
    end

    test "job not found", %{conn: conn} do
      expect(RPCWorkerMock, :run, fn _, _, :get_job, _args -> {:ok, nil} end)

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

  defp job(type, status, legal_entity, ended_at \\ nil) do
    %{
      id: UUID.generate(),
      type: type,
      status: status,
      meta: %{
        "deactivated_legal_entity" => %{
          "id" => legal_entity.id,
          "name" => legal_entity.name,
          "edrpou" => legal_entity.edrpou
        }
      },
      inserted_at: DateTime.utc_now(),
      ended_at: ended_at
    }
  end

  defp input_legal_entity_id(id) do
    %{
      input: %{
        id: Node.to_global_id("LegalEntity", id)
      }
    }
  end
end
