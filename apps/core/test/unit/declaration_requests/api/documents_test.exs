defmodule Core.Unit.DeclarationRequests.API.DocumentsTest do
  @moduledoc false

  use Core.ConnCase

  import Core.DeclarationRequests.API.Documents
  import Mox

  setup :verify_on_exit!

  describe "render_links/3" do
    test "generates links & updates declaration request" do
      expect(MediaStorageMock, :create_signed_url, 2, fn _, _, resource_name, resource_id, _ ->
        {:ok, %{"data" => %{"secret_url" => "http://a.link.for/#{resource_id}/#{resource_name}"}}}
      end)

      result = render_links("98e0a42f-20fe-472c-a614-0ea99426a3fb", ["PUT"], ["Passport", "tax_id"])

      expected_documents = [
        %{
          "type" => "tax_id",
          "verb" => "PUT",
          "url" => "http://a.link.for/98e0a42f-20fe-472c-a614-0ea99426a3fb/declaration_request_tax_id.jpeg"
        },
        %{
          "type" => "Passport",
          "verb" => "PUT",
          "url" => "http://a.link.for/98e0a42f-20fe-472c-a614-0ea99426a3fb/declaration_request_Passport.jpeg"
        }
      ]

      assert {:ok, expected_documents} == result
    end

    test "returns error on documents field" do
      expect(MediaStorageMock, :create_signed_url, fn _, _, _, _, _ ->
        {:error, %{"something" => "went wrong with declaration_request_Passport.jpeg"}}
      end)

      result = render_links("98e0a42f-0000-9999-5555-0ea99426a3fb", ["PUT"], ["Passport"])

      error_message = %{"something" => "went wrong with declaration_request_Passport.jpeg"}

      assert {:error, error_message} == result
    end
  end

  describe "gather_documents_list/1" do
    test "gathers all required docs" do
      person = %{
        "tax_id" => "some_id",
        "documents" => [
          %{"type" => "A"},
          %{"type" => "B"},
          %{"type" => "C"},
          %{"type" => "BIRTH_CERTIFICATE"},
          %{"type" => "PASSPORT"}
        ],
        "confidant_person" => [
          %{
            "tax_id" => "some_id",
            "relation_type" => "XXX",
            "documents_person" => [
              %{"type" => "A1"},
              %{"type" => "A2"},
              %{"type" => "A3"}
            ],
            "documents_relationship" => [
              %{"type" => "B1"},
              %{"type" => "B2"},
              %{"type" => "BIRTH_CERTIFICATE"}
            ]
          },
          %{
            "relation_type" => "YYY",
            "documents_person" => [
              %{"type" => "X1"},
              %{"type" => "X2"},
              %{"type" => "X3"}
            ],
            "documents_relationship" => [
              %{"type" => "Y1"},
              %{"type" => "Y2"}
            ]
          }
        ]
      }

      assert [
               "confidant_person.1.YYY.RELATIONSHIP.Y1",
               "confidant_person.1.YYY.RELATIONSHIP.Y2",
               "confidant_person.0.XXX.RELATIONSHIP.B1",
               "confidant_person.0.XXX.RELATIONSHIP.B2",
               "person.tax_id",
               "person.A",
               "person.B",
               "person.C",
               "person.BIRTH_CERTIFICATE",
               "person.PASSPORT"
             ] == gather_documents_list(person)
    end
  end
end
