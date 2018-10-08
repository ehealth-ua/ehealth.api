defmodule GraphQLWeb.LegalEntityResolverTest do
  use GraphQLWeb.ConnCase, async: true
  import Core.Factories

  setup %{conn: conn} do
    conn = put_scope(conn, "legal_entity:read legal_entity:write")

    {:ok, %{conn: conn}}
  end

  describe "list" do
    test "success without params", %{conn: conn} do
      insert(:prm, :legal_entity)
      insert(:prm, :legal_entity)

      query = """
        {
          legal_entities(first: 10) {
            nodes {
              id
              public_name
            }
          }
        }
      """

      legal_entities =
        conn
        |> post_query(query)
        |> json_response(200)
        |> get_in(~w(data legal_entities nodes))

      assert 2 == length(legal_entities)

      Enum.each(legal_entities, fn legal_entity ->
        assert Map.has_key?(legal_entity, "id")
        assert Map.has_key?(legal_entity, "public_name")
      end)
    end

    test "filter by edrpou", %{conn: conn} do
      insert(:prm, :legal_entity, edrpou: "1234567890")
      insert(:prm, :legal_entity, edrpou: "0987654321")

      query = """
        {
          legal_entities(first: 100, edrpou: "1234567890") {
            nodes {
              id
              edrpou
              public_name
            }
          }
        }
      """

      legal_entities =
        conn
        |> post_query(query)
        |> json_response(200)
        |> get_in(~w(data legal_entities nodes))

      assert 1 == length(legal_entities)
      assert "1234567890" == hd(legal_entities)["edrpou"]
    end

    test "paging", %{conn: conn} do
      insert(:prm, :legal_entity)
      insert(:prm, :legal_entity)
      insert(:prm, :legal_entity)

      query = """
        {
          legal_entities(first: 2) {
            page_info {
              start_cursor
              end_cursor
              has_previous_page
              has_next_page
            }
            nodes {
              id
              public_name
              addresses {
                type
                country
              }
            }
          }
        }
      """

      data =
        conn
        |> post_query(query)
        |> json_response(200)
        |> get_in(~w(data legal_entities))

      assert 2 == length(data["nodes"])
      assert data["page_info"]["has_next_page"]
      refute data["page_info"]["has_previous_page"]

      query = """
        {
          legal_entities(first: 2, after: "#{data["page_info"]["end_cursor"]}") {
            page_info {
              has_previous_page
              has_next_page
            }
            nodes {
              id
              public_name
            }
          }
        }
      """

      data =
        conn
        |> post_query(query)
        |> json_response(200)
        |> get_in(~w(data legal_entities))

      assert 1 == length(data["nodes"])
      refute data["page_info"]["has_next_page"]
      assert data["page_info"]["has_previous_page"]
    end
  end

  describe "get by id" do
    test "success", %{conn: conn} do
      insert(:prm, :legal_entity)
      phone = %{"type" => "MOBILE", "number" => "+380201112233"}
      legal_entity = insert(:prm, :legal_entity, phones: [phone])

      query = """
        {
          legal_entity(id: "#{legal_entity.id}") {
            id
            public_name
            nhs_verified
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
            medical_service_provider {
              licenses {
                license_number
                what_licensed
              }
              accreditation {
                category
              }
            }
          }
        }
      """

      resp =
        conn
        |> post_query(query)
        |> json_response(200)
        |> get_in(~w(data legal_entity))

      assert legal_entity.public_name == resp["public_name"]
      assert legal_entity.phones == resp["phones"]
      assert legal_entity.archive == resp["archive"]
      assert Map.has_key?(resp["medical_service_provider"], "licenses")
      assert "some" == get_in(resp, ~w(medical_service_provider accreditation category))
    end
  end

  describe "get by edrpou" do
  end
end
