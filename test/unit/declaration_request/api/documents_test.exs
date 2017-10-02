defmodule EHealth.Unit.DeclarationRequest.API.DocumentsTest do
  @moduledoc false

  use EHealth.Web.ConnCase
  import EHealth.DeclarationRequest.API.Documents

  describe "render_links/3" do
    defmodule UploadingFiles do
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
      on_exit fn ->
        System.put_env("MEDIA_STORAGE_ENDPOINT", "http://localhost:4040")
        stop_microservices(ref)
      end

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
end
