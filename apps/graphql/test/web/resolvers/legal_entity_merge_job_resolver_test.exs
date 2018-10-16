defmodule GraphQLWeb.LegalEntityMergeJobResolverTest do
  @moduledoc false

  use GraphQLWeb.ConnCase, async: true

  import Core.Factories
  import Mox

  alias Ecto.UUID

  @query """
    mutation MergeLegalEntitiesMutation($input: MergeLegalEntitiesInput!) {
      mergeLegalEntities(input: $input) {
        legalEntityMergeJob {
          id
          status
        }
      }
    }
  """

  setup %{conn: conn} do
    consumer_id = UUID.generate()

    conn =
      conn
      |> put_scope("legal_entity:merge")
      |> put_consumer_id(consumer_id)

    {:ok, %{conn: conn}}
  end

  describe "merge legal entities" do
    test "success", %{conn: conn} do
      expect(SignatureMock, :decode_and_validate, fn signed_content, "base64", _headers ->
        content = signed_content |> Base.decode64!() |> Jason.decode!()

        data = %{
          "content" => content,
          "signatures" => [
            %{
              "is_valid" => true,
              "signer" => %{
                "drfo" => content["tax_id"],
                "surname" => content["last_name"],
                "given_name" => "Сара Коннор"
              },
              "validation_error_message" => ""
            }
          ]
        }

        {:ok, %{"data" => data}}
      end)

      from = insert(:prm, :legal_entity)
      to = insert(:prm, :legal_entity)

      signed_content =
        %{
          "merged_from_legal_entity" => %{
            "id" => from.id,
            "name" => from.name,
            "edrpou" => from.edrpou
          },
          "merged_to_legal_entity" => %{
            "id" => to.id,
            "name" => to.name,
            "edrpou" => to.edrpou
          },
          "reason" => "Because I can"
        }
        |> Jason.encode!()
        |> Base.encode64()

      variables = %{
        input: %{
          signedContent: %{
            content: signed_content,
            encoding: "BASE64"
          }
        }
      }

      job =
        conn
        |> post_query(@query, variables)
        |> json_response(200)
        |> get_in(~w(data mergeLegalEntities legalEntityMergeJob))

      assert "PENDING" == job["status"]
    end

    test "invalid scope", %{conn: conn} do
      resp =
        conn
        |> put_scope("scope:not-allowed")
        |> post_query(@query, %{
          input: %{
            signedContent: %{
              content: "",
              encoding: "BASE64"
            }
          }
        })
        |> json_response(200)

      assert match?(%{"mergeLegalEntities" => nil}, resp["data"])
      assert Enum.any?(resp["errors"], &match?(%{"extensions" => %{"code" => "FORBIDDEN"}}, &1))
    end
  end
end
