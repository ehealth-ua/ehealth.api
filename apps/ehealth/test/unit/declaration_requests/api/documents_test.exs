defmodule EHealth.Unit.DeclarationRequests.API.DocumentsTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import EHealth.DeclarationRequests.API.Documents

  describe "render_links/3" do
    defmodule UploadingFiles do
      @moduledoc false

      use MicroservicesHelper

      Plug.Router.post "/media_content_storage_secrets" do
        %{
          "secret" => %{
            "action" => _,
            "bucket" => _,
            "resource_id" => resource_id,
            "resource_name" => resource_name,
            "content_type" => "image/jpeg"
          }
        } = conn.body_params

        case resource_id do
          "98e0a42f-20fe-472c-a614-0ea99426a3fb" ->
            upload = %{
              secret_url: "http://a.link.for/#{resource_id}/#{resource_name}"
            }

            Plug.Conn.send_resp(conn, 200, Poison.encode!(%{data: upload}))

          "98e0a42f-0000-9999-5555-0ea99426a3fb" ->
            Plug.Conn.send_resp(conn, 500, Poison.encode!(%{something: "went wrong with #{resource_name}"}))
        end
      end
    end

    setup %{conn: _conn} do
      {:ok, port, ref} = start_microservices(UploadingFiles)

      System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:#{port}")

      on_exit(fn ->
        System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end)

      :ok
    end

    test "generates links & updates declaration request" do
      result = render_links("98e0a42f-20fe-472c-a614-0ea99426a3fb", ["PUT"], ["Passport", "SSN"])

      expected_documents = [
        %{
          "type" => "SSN",
          "verb" => "PUT",
          "url" => "http://a.link.for/98e0a42f-20fe-472c-a614-0ea99426a3fb/declaration_request_SSN.jpeg"
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
