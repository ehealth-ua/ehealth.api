defmodule GraphQLWeb.MergeRequestResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: true

  import Core.Expectations.Mithril, only: [nhs: 1, search_user_roles: 1]
  import Core.Factories
  import Mox

  alias Ecto.UUID
  alias Absinthe.Relay.Node

  @person_fields """
    lastName
    birthDate
    gender
    status
    birthCountry
    taxId
    unzr
    documents {
      type
      number
    }
    authenticationMethods {
      type
      phoneNumber
    }
  """

  @merge_request_fields """
    id
    databaseId
    status
    comment
    insertedAt
    updatedAt

    manualMergeCandidate {
      id
      databaseId
      status
      insertedAt
      updatedAt
      mergeCandidate {
        id
        databaseId
        person {
          #{@person_fields}
        }
        masterPerson {
          #{@person_fields}
        }
      }
    }
  """

  @merge_requests_query """
    query MergeRequestsQuery($orderBy: MergeRequestOrderBy) {
      mergeRequests(first: 10, orderBy: $orderBy) {
        canAssignNew
        nodes {
          #{@merge_request_fields}
        }
      }
    }
  """

  @merge_request_by_id_query """
    query GetMergeRequestQuery($id: ID!) {
      mergeRequest(id: $id) {
        #{@merge_request_fields}
      }
    }
  """

  setup :verify_on_exit!

  describe "list pending MergeRequests" do
    test "success with search params", %{conn: conn} do
      consumer_id = UUID.generate()

      merge_candidate = build(:merge_candidate)
      manual_merge_candidate = build(:manual_merge_candidate, merge_candidate: merge_candidate)

      manual_merge_requests =
        build_list(2, :manual_merge_request, assignee_id: consumer_id, manual_merge_candidate: manual_merge_candidate)

      nhs(1)
      search_user_roles("NHS REVIEWER")

      expect(RPCWorkerMock, :run, fn _, _, :search_manual_merge_requests, [filter | _] = _params ->
        assert {:assignee_id, :equal, consumer_id} in filter

        {:ok, manual_merge_requests}
      end)

      variables = %{orderBy: "STATUS_ASC"}

      resp_body =
        conn
        |> put_client_id()
        |> put_consumer_id(consumer_id)
        |> put_scope("merge_request:read")
        |> post_query(@merge_requests_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data mergeRequests nodes))

      refute resp_body["errors"]
      assert 2 == length(resp_entities)
    end

    test "success: empty results", %{conn: conn} do
      nhs(1)
      search_user_roles("NHS REVIEWER")

      expect(RPCWorkerMock, :run, fn _, _, :search_manual_merge_requests, _ -> {:ok, []} end)
      variables = %{}

      resp_body =
        conn
        |> put_client_id()
        |> put_consumer_id()
        |> put_scope("merge_request:read")
        |> post_query(@merge_requests_query, variables)
        |> json_response(200)

      resp_entities = get_in(resp_body, ~w(data mergeRequests nodes))

      refute resp_body["errors"]
      assert [] == resp_entities
    end

    test "forbidden on invalid role", %{conn: conn} do
      nhs(1)
      search_user_roles("NHS ADMIN")
      variables = %{}

      resp_body =
        conn
        |> put_client_id()
        |> put_consumer_id()
        |> put_scope("merge_request:read")
        |> post_query(@merge_requests_query, variables)
        |> json_response(200)

      %{"errors" => [error]} = resp_body

      refute get_in(resp_body, ~w(data mergeRequests nodes))
      assert "FORBIDDEN" == error["extensions"]["code"]
    end
  end

  describe "get by id" do
    test "success", %{conn: conn} do
      consumer_id = UUID.generate()

      merge_candidate = build(:merge_candidate)
      manual_merge_candidate = build(:manual_merge_candidate, merge_candidate: merge_candidate)

      manual_merge_request =
        build(:manual_merge_request, assignee_id: consumer_id, manual_merge_candidate: manual_merge_candidate)

      expect(RPCWorkerMock, :run, fn _, _, :search_manual_merge_requests, _ ->
        {:ok, [manual_merge_request]}
      end)

      variables = %{id: Node.to_global_id("MergeRequest", manual_merge_request.id)}

      nhs(1)
      search_user_roles("NHS REVIEWER")

      resp_body =
        conn
        |> put_client_id()
        |> put_consumer_id(consumer_id)
        |> put_scope("merge_request:read")
        |> post_query(@merge_request_by_id_query, variables)
        |> json_response(200)

      resp_entity = get_in(resp_body, ~w(data mergeRequest))

      refute resp_body["errors"]
      assert manual_merge_request.id == resp_entity["databaseId"]
    end

    test "not found", %{conn: conn} do
      expect(RPCWorkerMock, :run, fn _, _, :search_manual_merge_requests, _ -> {:ok, []} end)
      variables = %{id: Node.to_global_id("MergeRequest", UUID.generate())}

      nhs(1)
      search_user_roles("NHS REVIEWER")

      resp_body =
        conn
        |> put_client_id()
        |> put_consumer_id()
        |> put_scope("merge_request:read")
        |> post_query(@merge_request_by_id_query, variables)
        |> json_response(200)

      assert Map.has_key?(resp_body["data"], "mergeRequest")
      refute get_in(resp_body, ~w(data mergeRequest))
    end
  end
end
