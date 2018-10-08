defmodule GraphQLWeb.AuthorizationMiddlewareTest do
  use GraphQLWeb.ConnCase, async: true

  @query """
    {
      legalEntities(first: 10) {
        nodes {
          id
        }
      }
    }
  """

  describe "authorization" do
    test "success with given scope which includes requested scope", %{conn: conn} do
      resp_body =
        conn
        |> put_scope("legal_entity:read")
        |> post_query(@query)
        |> json_response(200)

      data = Map.get(resp_body, "data")
      errors = Map.get(resp_body, "errors", [])

      refute match?(%{"legalEntities" => nil}, data)
      refute Enum.any?(errors, &match?(%{"extensions" => %{"code" => "FORBIDDEN"}}, &1))
    end

    test "fail with given scope which does not include requested scope", %{conn: conn} do
      resp_body =
        conn
        |> put_scope("person:read")
        |> post_query(@query)
        |> json_response(200)

      data = Map.get(resp_body, "data")
      errors = Map.get(resp_body, "errors", [])

      assert match?(%{"legalEntities" => nil}, data)
      assert Enum.any?(errors, &match?(%{"extensions" => %{"code" => "FORBIDDEN"}}, &1))
    end

    test "fail with empty given scope when requested scope present", %{conn: conn} do
      resp_body =
        conn
        |> post_query(@query)
        |> json_response(200)

      data = Map.get(resp_body, "data")
      errors = Map.get(resp_body, "errors", [])

      assert match?(%{"legalEntities" => nil}, data)
      assert Enum.any?(errors, &match?(%{"extensions" => %{"code" => "FORBIDDEN"}}, &1))
    end
  end
end
